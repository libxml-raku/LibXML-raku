/* $Id$
 *
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2001-2003 AxKit.com Ltd., 2002-2006 Christian Glahn, 2006-2009 Petr Pajas
 * Ported from Perl 5 to 6 by David Warring
 */

#include <libxml/hash.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/uri.h>

#include "dom.h"
#include "domXPath.h"
#include "xml6.h"
#include "xml6_node.h"
#include "xml6_ref.h"

void
perlDocumentFunction(xmlXPathParserContextPtr ctxt, int nargs){
    xmlXPathObjectPtr obj = NULL, obj2 = NULL;
    xmlChar* base = NULL;
    xmlChar* URI = NULL;

    if ((nargs < 1) || (nargs > 2)) {
        ctxt->error = XPATH_INVALID_ARITY;
        return;
    }
    if (ctxt->value == NULL) {
        ctxt->error = XPATH_INVALID_TYPE;
        return;
    }

    if (nargs == 2) {
        if (ctxt->value->type != XPATH_NODESET) {
            ctxt->error = XPATH_INVALID_TYPE;
            return;
        }

        obj2 = valuePop(ctxt);
    }


    /* first assure the LibXML error handler is deactivated
       otherwise strange things might happen
    */

    if (ctxt->value->type == XPATH_NODESET) {
        int i;
        xmlXPathObjectPtr newobj, ret;

        obj = valuePop(ctxt);
        ret = xmlXPathNewNodeSet(NULL);

        if (obj->nodesetval) {
            for (i = 0; i < obj->nodesetval->nodeNr; i++) {
                valuePush(ctxt,
                          xmlXPathNewNodeSet(obj->nodesetval->nodeTab[i]));
                xmlXPathStringFunction(ctxt, 1);
                if (nargs == 2) {
                    valuePush(ctxt, xmlXPathObjectCopy(obj2));
                } else {
                    valuePush(ctxt,
                              xmlXPathNewNodeSet(obj->nodesetval->nodeTab[i]));
                }
                perlDocumentFunction(ctxt, 2);
                newobj = valuePop(ctxt);
                ret->nodesetval = xmlXPathNodeSetMerge(ret->nodesetval,
                                                       newobj->nodesetval);
                newobj->nodesetval = NULL;
                xmlXPathFreeObject(newobj);
            }
        }

        xmlXPathFreeObject(obj);
        if (obj2 != NULL)
            xmlXPathFreeObject(obj2);
        valuePush(ctxt, ret);

        return;
    }
    /*
     * Make sure it's converted to a string
     */
    xmlXPathStringFunction(ctxt, 1);
    if (ctxt->value->type != XPATH_STRING) {
        ctxt->error = XPATH_INVALID_TYPE;
        if (obj2 != NULL)
            xmlXPathFreeObject(obj2);

        return;
    }
    obj = valuePop(ctxt);
    if (obj->stringval == NULL) {
        valuePush(ctxt, xmlXPathNewNodeSet(NULL));
    } else {
        if ((obj2 != NULL) && (obj2->nodesetval != NULL) &&
            (obj2->nodesetval->nodeNr > 0)) {
            xmlNodePtr target;

            target = obj2->nodesetval->nodeTab[0];
            if (target->type == XML_ATTRIBUTE_NODE) {
                target = ((xmlAttrPtr) target)->parent;
            }
            base = xmlNodeGetBase(target->doc, target);
        } else {
            base = xmlNodeGetBase(ctxt->context->node->doc, ctxt->context->node);
        }
        URI = xmlBuildURI(obj->stringval, base);
        if (base != NULL)
            xmlFree(base);
        if (URI == NULL) {
            valuePush(ctxt, xmlXPathNewNodeSet(NULL));
        } else {
            if (xmlStrEqual(ctxt->context->node->doc->URL, URI)) {
                valuePush(ctxt, xmlXPathNewNodeSet((xmlNodePtr)ctxt->context->node->doc));
            }
            else {
                xmlDocPtr doc;
                doc = xmlParseFile((const char *)URI);
                if (doc == NULL)
                    valuePush(ctxt, xmlXPathNewNodeSet(NULL));
                else {
                    /* TODO: use XPointer of HTML location for fragment ID */
                    /* pbm #xxx can lead to location sets, not nodesets :-) */
                    valuePush(ctxt, xmlXPathNewNodeSet((xmlNodePtr) doc));
                }
            }
            xmlFree(URI);
        }
    }
    xmlXPathFreeObject(obj);
    if (obj2 != NULL)
        xmlXPathFreeObject(obj2);
}

void
domReferenceNodeSet(xmlNodeSetPtr self) {
    int i;

    for (i = 0; i < self->nodeNr; i++) {
        xmlNodePtr cur = self->nodeTab[i];

        if (cur != NULL) {
            if (cur->type != XML_NAMESPACE_DECL) {
                xml6_node_add_reference(cur);
            }
        }
    }
}

static void
_domNodeSetDeallocator(void *entry, unsigned char *key ATTRIBUTE_UNUSED) {
    xmlNodePtr twig = (xmlNodePtr) entry;
    if (twig->type == XML_NAMESPACE_DECL) {
        xmlNsPtr ns = (xmlNsPtr) twig;
        if (ns->_private == NULL) {
            // not referenced
            xmlXPathNodeSetFreeNs(ns);
        }
        else {
            // sanity check for externally referenced namespaces. shouldn't really happen
            xml6_warn("namespace node is inuse or private");
        }
    }
    else {
        if (domNodeIsReferenced(twig) == 0) {
            xmlFreeNode(twig);
        }
    }
}

void
domReleaseNodeSet(xmlNodeSetPtr self) {
    int i;
    xmlHashTablePtr hash = xmlHashCreate(self->nodeNr);
    xmlNodePtr last_twig = NULL;

    for (i = 0; i < self->nodeNr; i++) {
        xmlNodePtr cur = self->nodeTab[i];

        if (cur != NULL) {
            xmlNodePtr twig;

            if (cur->type == XML_NAMESPACE_DECL) {
                twig = cur;
            }
            else {
                xml6_node_remove_reference(cur);
                twig = xml6_node_find_root(cur);
            }

            if (twig != last_twig) {
                char key[20];
                sprintf(key, "%ld", (long) cur);

                if (xmlHashLookup(hash, (xmlChar*)key) == NULL) {
                    xmlHashAddEntry(hash, xmlStrdup((xmlChar*)key), twig);
                }

                last_twig = twig;
            }
        }
    }

    xmlHashFree(hash, _domNodeSetDeallocator);
    xmlFree(self);
}

static xmlXPathObjectPtr
_domXPathFindStr( xmlNodePtr refNode, xmlChar* path) {
    xmlXPathObjectPtr rv = NULL;
    xmlXPathCompExprPtr comp = xmlXPathCompile( path );
    if ( comp == NULL ) {
        fprintf(stderr, "%s:%d: invalid xpath expression: %s\n", __FILE__, __LINE__, path);
        return NULL;
    }
    rv = domXPathFind(refNode, comp, 0);
    xmlXPathFreeCompExpr(comp);
    return rv;
}

static xmlNodeSetPtr
_domVetNodeSet(xmlNodeSetPtr node_set) {

    if (node_set != NULL ) {
        int i = 0;
        int n = 0;

        for (i = 0; i < node_set->nodeNr; i++) {
            xmlNodePtr tnode = node_set->nodeTab[i];
            int skip = 0;
            if (tnode != NULL && tnode->type == XML_NAMESPACE_DECL) {
                xmlNsPtr ns = (xmlNsPtr)tnode;
                const xmlChar* prefix = ns->prefix;
                const xmlChar* href = ns->href;
                if ((prefix != NULL) && (xmlStrEqual(prefix, BAD_CAST "xml"))) {
                    if (xmlStrEqual(href, XML_XML_NAMESPACE)) {
                        if (ns->_private != NULL) {
                            // sanity check for externally referenced namespaces. shouldn't really happen
                            xml6_warn("namespace node is inuse or private");
                        }
                        else {
                            xmlFreeNs(ns);
                        }
                        skip = 1;
                    }
                }
            }
            if (!skip) {
                if (n < i)
                    node_set->nodeTab[n] = node_set->nodeTab[i];
                n++;
            }
        }
        node_set->nodeNr = n;
    }
    return node_set;
}

static xmlXPathObjectPtr
_domVetXPathObject(xmlXPathObjectPtr self) {
    if (self != NULL
        && self->type == XPATH_NODESET
        && self->nodesetval != NULL) {
        _domVetNodeSet(self->nodesetval);
    }
    return self;
}

static xmlNsPtr *_domXPathCtxtInheritNS(xmlXPathContextPtr ctxt, xmlDocPtr doc) {
    /* inherit namespace information */
    xmlNsPtr *ns = xmlGetNsList(doc, xmlDocGetRootElement( doc ));
    if (ns != NULL) {
        int i;
        int n = 0;
        for (i = 0; ns[i] != NULL; i++) {
            const xmlChar *prefix = ns[i]->prefix;

            if (xmlXPathNsLookup(ctxt, prefix ) == NULL) {
                xmlXPathRegisterNs(ctxt, prefix, ns[i]->href);
                if (n < i)
                    ns[n] = ns[i];
                n++;
            }
        }
        // shorten the ns list to just those inherited
        ns[n] = NULL;
    }
    return ns;
}

static void _domXPathCtxtRemoveNS(xmlXPathContextPtr ctxt, xmlNsPtr *ns) {
    int i;
    for (i = 0; ns[i] != NULL; i++) {
        // deregister
        xmlXPathRegisterNs(ctxt, ns[i]->prefix, NULL);
    }
}

xmlNodePtr
domXPathCtxtSetNode(xmlXPathContextPtr ctxt, xmlNodePtr node) {
    xmlNodePtr oldNode = ctxt->node;

    if (node != oldNode) {
        xmlDocPtr doc = node ? node->doc : NULL;
        if (ctxt->doc != doc) {
            if (ctxt->doc != NULL)
                fail(node, "changing XPath Context documents is not supported");

            ctxt->doc = doc;

            if (doc) {
                xmlNsPtr *ns = _domXPathCtxtInheritNS(ctxt, doc);
                if (ns != NULL)
                     xmlFree(ns);
            }
        }
        ctxt->node = node;
    }

    return oldNode;
}

xmlXPathContextPtr
domXPathNewCtxt(xmlNodePtr refNode) {
    xmlXPathContextPtr ctxt = xmlXPathNewContext( NULL );
    xmlXPathRegisterFunc(ctxt,
                         (const xmlChar*) "document",
                         perlDocumentFunction);

    if (refNode) {
        domXPathCtxtSetNode(ctxt, refNode);
    }
    return ctxt;
}

void
domXPathFreeCtxt(xmlXPathContextPtr ctxt) {
    if (ctxt->namespaces != NULL) {
        xmlFree( ctxt->namespaces );
        ctxt->namespaces = NULL;
    }
    xmlXPathFreeContext(ctxt);
}


xmlXPathObjectPtr
domXPathFind( xmlNodePtr refNode, xmlXPathCompExprPtr comp, int to_bool ) {
    xmlXPathObjectPtr rv = NULL;
    if ( refNode != NULL && comp != NULL ) {
        xmlXPathContextPtr ctxt = domXPathNewCtxt(refNode);
        rv = domXPathFindCtxt(ctxt, comp, refNode, to_bool);
        domXPathFreeCtxt(ctxt);
    }
    return rv;
}


xmlNodeSetPtr
domXPathSelectNodeSet(xmlXPathObjectPtr xpath_obj) {
    xmlNodeSetPtr rv = NULL;
    if (xpath_obj != NULL) {
        /* here we have to transfer the result from the internal
           structure to the return value */
        /* get the result from an xpath query */
        /* we have to unbind the nodelist, so free object can
           not kill it */
        rv = xpath_obj->nodesetval;
        xpath_obj->nodesetval = NULL;
    }
    return _domVetNodeSet(rv);
}

static xmlNodeSetPtr
_domSelect(xmlXPathObjectPtr xpath_obj) {
    return domXPathSelectNodeSet(xpath_obj);
}

xmlNodeSetPtr
domXPathSelectStr( xmlNodePtr refNode, xmlChar* path ) {
    return _domSelect( _domXPathFindStr( refNode, path ) );
}


xmlNodeSetPtr
domXPathSelect( xmlNodePtr refNode, xmlXPathCompExprPtr comp ) {
    return _domSelect( domXPathFind( refNode, comp, 0 ));
}

xmlXPathObjectPtr
domXPathFindCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode, int to_bool ) {
    xmlXPathObjectPtr rv = NULL;
    if ( ctxt != NULL && (ctxt->node != NULL || refNode != NULL) && comp != NULL ) {
        xmlNodePtr old_node = ctxt->node;
        xmlDocPtr old_doc = ctxt->doc;
        xmlNsPtr *inherited_ns = NULL;
        if (refNode) {
            ctxt->node = refNode;
            ctxt->doc  = refNode->doc;
            if (ctxt->doc != old_doc && ctxt->doc != NULL)
                inherited_ns = _domXPathCtxtInheritNS(ctxt, ctxt->doc);
        }
        if (to_bool) {
#if LIBXML_VERSION >= 20627
            int val = xmlXPathCompiledEvalToBoolean(comp, ctxt);
            rv = xmlXPathNewBoolean(val);
#else
            rv = xmlXPathCompiledEval(comp, ctxt);
            if (rv != NULL) {
                int val = xmlXPathCastToBoolean(rv);
                xmlXPathFreeObject(rv);
                rv = xmlXPathNewBoolean(val);
            }
#endif
        } else {
            rv = xmlXPathCompiledEval(comp, ctxt);
        }

        ctxt->node = old_node;
        ctxt->doc = old_doc;
        if (inherited_ns) {
            _domXPathCtxtRemoveNS(ctxt, inherited_ns);
            xmlFree(inherited_ns);
        }
    }
    return _domVetXPathObject(rv);
}

xmlNodeSetPtr
domXPathSelectCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode) {
    return _domSelect(domXPathFindCtxt(ctxt, comp, refNode, 0));
}


