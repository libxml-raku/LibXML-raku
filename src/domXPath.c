/* $Id$
 *
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2001-2003 AxKit.com Ltd., 2002-2006 Christian Glahn, 2006-2009 Petr Pajas
 * Ported from Perl to Raku by David Warring
 */

#include <libxml/hash.h>
#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/xpathInternals.h>
#include <libxml/uri.h>
#include <string.h>
#include <assert.h>

#include "dom.h"
#include "domXPath.h"
#include "xml6.h"
#include "xml6_node.h"
#include "xml6_ns.h"
#include "xml6_ref.h"

static xmlNodePtr _domItemOwner(xmlNodePtr item) {
    xmlNodePtr owner = NULL;
    if (item != NULL) {
        if (item->type == XML_NAMESPACE_DECL) {
            xmlNsPtr ns = (xmlNsPtr)item;
            if (ns->next && ns->next->type != XML_NAMESPACE_DECL) {
                owner = (xmlNodePtr) ns->next;
            }
        }
        else {
            owner = item;
        }
    }
    return owner;
}

static xmlNodePtr _domNewItem(xmlNodePtr item) {
    xmlNodePtr owner = _domItemOwner(item);

    if (!owner && item->type == XML_NAMESPACE_DECL) {
         item = (xmlNodePtr) xml6_ns_copy((xmlNsPtr)item);
    }
 
    return item;
}

static xmlNodePtr _domReferenceItem(xmlNodePtr item) {
    xmlNodePtr owner = _domItemOwner(item);
    if (owner != NULL) {
        xml6_node_add_reference(owner);
    }
    return item;
}

static xmlNodePtr _domUnreferenceItem(xmlNodePtr item) {
    xmlNodePtr owner = _domItemOwner(item);
    if (owner != NULL) {
        xml6_node_remove_reference(owner);
    }
    return owner;
}

// Node Sets don't support reference counting. They should
// only be referenced once.
DLLEXPORT void
domReferenceNodeSet(xmlNodeSetPtr self) {
    int i;

    for (i = 0; i < self->nodeNr; i++) {
        _domReferenceItem( self->nodeTab[i]);
    }
}

DLLEXPORT xmlNodePtr
domNodeSetAtPos(xmlNodeSetPtr self, int i) {
    if (self && i >= 0 && i < self->nodeNr) {
        return self->nodeTab[i];
    }
    return NULL;
}

static xmlNodeSetPtr _domResizeNodeSet(xmlNodeSetPtr rv, int nodeMax) {
    xmlNodePtr *temp;
    int size;

    if (nodeMax < 10)
        nodeMax = 10;

    size = nodeMax * sizeof(xmlNodePtr);

    if (rv->nodeTab == NULL) {
        temp = (xmlNodePtr *) xmlMalloc(size);
    }
    else {
        temp = (xmlNodePtr *) xmlRealloc(rv->nodeTab, size);
    }

    assert(temp != NULL);

    rv->nodeMax = nodeMax;
    rv->nodeTab = temp;

    return rv;
}

DLLEXPORT void
domPushNodeSet(xmlNodeSetPtr self, xmlNodePtr item, int reference) {
    assert(self != NULL);
    assert(item != NULL);

    xmlNodePtr new_item = _domNewItem(item);
    if (reference) _domReferenceItem(new_item);

    if (self->nodeNr >= self->nodeMax) {
        _domResizeNodeSet(self, self->nodeMax * 2);
    }

    self->nodeTab[self->nodeNr++] = new_item;
}

DLLEXPORT xmlNodeSetPtr
domCreateNodeSetFromList(xmlNodePtr item, int keep_blanks) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    int n = 0;
    assert(rv != NULL);

    while (item != NULL) {
        if (n >= rv->nodeMax) {
            _domResizeNodeSet(rv, rv->nodeMax * 2);
        }

        rv->nodeTab[n++] = _domNewItem(item);

        if (item->type == XML_NAMESPACE_DECL) {
            item = (xmlNodePtr) ((xmlNsPtr) item)->next;
        }
        else {
            item = xml6_node_next(item, keep_blanks);
        }
    }
    rv->nodeNr = n;

    return rv;
}

DLLEXPORT xmlNodePtr domPopNodeSet(xmlNodeSetPtr self) {
    xmlNodePtr rv = NULL;
    assert(self != NULL);
    if (self->nodeNr > 0) {
        rv = self->nodeTab[--self->nodeNr];
        _domUnreferenceItem(rv);
    }
    return rv;
}

DLLEXPORT xmlNodeSetPtr domCopyNodeSet(xmlNodeSetPtr self) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    int i;

    assert(rv != NULL);

    if (self != NULL) {

        if (self->nodeNr > rv->nodeMax) {
            _domResizeNodeSet(rv, self->nodeNr);
        }

        for (i = 0; i < self->nodeNr; i++) {
            xmlNodePtr item = self->nodeTab[i];
            rv->nodeTab[i] = _domNewItem(item);
        }
        rv->nodeNr = self->nodeNr;
    }

    return rv;
}

DLLEXPORT xmlNodeSetPtr domReverseNodeSet(xmlNodeSetPtr rv) {
    xmlNodePtr temp;
    int i;
    int mid = rv->nodeNr / 2;
    int last = rv->nodeNr - 1;

    for (i = 0; i < mid; i++) {
        temp = rv->nodeTab[i];
        rv->nodeTab[i] = rv->nodeTab[last - i];
        rv->nodeTab[last - i] = temp;
    }

    return rv;
}

static void
_domNodeSetGC(void *entry, unsigned char* _) {
    xmlNodePtr twig = (xmlNodePtr) entry;
    xmlNodePtr owner = _domItemOwner(twig);
    if (owner) {
        int orphaned = owner->parent == NULL && owner->prev == NULL && owner->next == NULL;
        if (orphaned) {
            domReleaseNode(owner);
        }
    }
    else {
        if (twig->type == XML_NAMESPACE_DECL) {
            xmlNsPtr ns = (xmlNsPtr) twig;
            ns->next = NULL;

            if (ns->_private == NULL) {
                // not referenced
                xmlXPathNodeSetFreeNs(ns);
            }
            else {
                // we're not reference counting xmlNs objects
                xml6_warn("namespace node is inuse or private");
            }
        }
    }
}

DLLEXPORT int domDeleteNodeSetItem(xmlNodeSetPtr self, xmlNodePtr item) {
    int pos = -1;
    int i;
    assert(self != NULL);
    assert(item != NULL);
    for (i = 0; i < self->nodeNr; i++) {
        xmlNodePtr elem = self->nodeTab[i];
        if (pos >= 0) {
            self->nodeTab[i-1] = self->nodeTab[i];
        }
        else if (elem == item) {
            _domUnreferenceItem(elem);
            _domNodeSetGC(elem, NULL);
            pos = i;
        }
    }
    if (pos >= 0) {
        self->nodeNr--;
    }
    return pos;
}

DLLEXPORT void
domUnreferenceNodeSet(xmlNodeSetPtr self) {
    int i;
    xmlHashTablePtr gc = xmlHashCreate(self->nodeNr);
    xmlNodePtr last_twig = NULL;

    for (i = 0; i < self->nodeNr; i++) {
        xmlNodePtr cur = self->nodeTab[i];

        if (cur != NULL) {
            xmlNodePtr twig = _domUnreferenceItem(cur);
            if (!twig) {
                if (cur->type == XML_NAMESPACE_DECL) {
                    _domNodeSetGC(cur, NULL);
                }
            }
            else {
                twig = xml6_node_find_root(twig);

                if (twig != last_twig) {
                    char key[20];
                    sprintf(key, "%p", cur);

                    if (xmlHashLookup(gc, (xmlChar*)key) == NULL) {
                        xmlHashAddEntry(gc, xmlStrdup((xmlChar*)key), twig);
                    }

                    last_twig = twig;
                }
            }
        }
    }

    xmlHashFree(gc, (xmlHashDeallocator) _domNodeSetGC);
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

static xmlNsPtr *_domXPathCtxtRegisterNS(xmlXPathContextPtr ctxt, xmlNodePtr node) {
    /* register namespace information from the context node */
    xmlDocPtr doc = node->doc;
    xmlNsPtr *ns = NULL;

    if ((xmlDocPtr)node == doc) node = xmlDocGetRootElement( doc );
    ns = xmlGetNsList(doc, node);

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
        // shorten the list to just newly registered ns
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

DLLEXPORT xmlNodePtr
domXPathCtxtSetNode(xmlXPathContextPtr ctxt, xmlNodePtr node) {
    xmlNodePtr oldNode = ctxt->node;
    xmlNsPtr* ns_list = NULL;

    if (node != oldNode) {
        xmlDocPtr doc = node ? node->doc : NULL;
        if (ctxt->doc != doc) {
            if (ctxt->doc != NULL) {
                XML6_FAIL(node, "changing XPath Context documents is not supported");
            }
            ctxt->doc = doc;
        }

        ns_list = _domXPathCtxtRegisterNS(ctxt, node);
        if (ns_list != NULL) {
            xmlFree(ns_list);
        }
        ctxt->node = node;
    }

    return oldNode;
}

static void
_documentFunction(xmlXPathParserContextPtr ctxt, int nargs) {
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
                _documentFunction(ctxt, 2);
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

DLLEXPORT xmlXPathContextPtr
domXPathNewCtxt(xmlNodePtr refNode) {
    xmlXPathContextPtr ctxt = xmlXPathNewContext( NULL );
    xmlXPathRegisterFunc(ctxt,
                         (const xmlChar*) "document",
                         _documentFunction);

    if (refNode) {
        domXPathCtxtSetNode(ctxt, refNode);
    }
    return ctxt;
}

DLLEXPORT void
domSetXPathCtxtErrorHandler(xmlXPathContextPtr ctxt, xmlStructuredErrorFunc error_func) {
    ctxt->error = error_func;
}

DLLEXPORT void
domXPathFreeCtxt(xmlXPathContextPtr ctxt) {
    if (ctxt->namespaces != NULL) {
        xmlFree( ctxt->namespaces );
        ctxt->namespaces = NULL;
    }
    xmlXPathFreeContext(ctxt);
}


DLLEXPORT xmlXPathObjectPtr
domXPathFind( xmlNodePtr refNode, xmlXPathCompExprPtr comp, int to_bool ) {
    xmlXPathObjectPtr rv = NULL;
    if ( refNode != NULL && comp != NULL ) {
        xmlXPathContextPtr ctxt = domXPathNewCtxt(refNode);
        rv = domXPathFindCtxt(ctxt, comp, refNode, to_bool);
        domXPathFreeCtxt(ctxt);
    }
    return rv;
}


DLLEXPORT xmlNodeSetPtr
domXPathGetNodeSet(xmlXPathObjectPtr xpath_obj, int select) {
    xmlNodeSetPtr rv = NULL;
    if (xpath_obj != NULL && (xpath_obj->type == XPATH_NODESET || xpath_obj->type == XPATH_XSLT_TREE)) {
        /* here we have to transfer the result from the internal
           structure to the return value */
        /* get the result from an xpath query */
        /* we have to unbind the nodelist, so free object can
           not kill it */
        rv = xpath_obj->nodesetval;
        if (select) {
            xpath_obj->nodesetval = NULL;
        }
    }
    return _domVetNodeSet(rv);
}

DLLEXPORT xmlXPathObjectPtr
domXPathNewPoint(xmlNodePtr node, int indx) {
    xmlXPathObjectPtr rv;

    if (node == NULL)
	return(NULL);
    if (indx < 0)
	return(NULL);

    rv = (xmlXPathObjectPtr) xmlMalloc(sizeof(xmlXPathObject));
    if (rv == NULL) {
        XML6_FAIL(node, "allocating point");
	return(NULL);
    }
    memset(rv, 0 , (size_t) sizeof(xmlXPathObject));
    rv->type = XPATH_POINT;
    rv->user = (void *) node;
    rv->index = indx;
    return rv;
}


DLLEXPORT xmlNodePtr
domXPathGetPoint(xmlXPathObjectPtr xpath_obj, int select) {
    xmlNodePtr rv = NULL;
    if (xpath_obj != NULL && xpath_obj->type == XPATH_POINT) {
        rv = (xmlNodePtr)xpath_obj->user;
        if (select) {
            xpath_obj->user = NULL;
        }
    }
    return rv;
}

static xmlNodeSetPtr
_domSelect(xmlXPathObjectPtr xpath_obj) {
    return domXPathGetNodeSet(xpath_obj, 1);
}

DLLEXPORT xmlNodeSetPtr
domXPathSelectStr( xmlNodePtr refNode, xmlChar* path ) {
    return _domSelect(_domXPathFindStr( refNode, path ) );
}


DLLEXPORT xmlNodeSetPtr
domXPathSelect( xmlNodePtr refNode, xmlXPathCompExprPtr comp ) {
    return _domSelect( domXPathFind( refNode, comp, 0 ));
}

DLLEXPORT xmlXPathObjectPtr
domXPathFindCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode, int to_bool ) {
    xmlXPathObjectPtr rv = NULL;
    if ( ctxt != NULL && (ctxt->node != NULL || refNode != NULL) && comp != NULL ) {
        xmlNodePtr old_node = ctxt->node;
        xmlDocPtr old_doc = ctxt->doc;
        xmlNsPtr *registered_ns = NULL;
        if (refNode) {
            ctxt->node = refNode;
            ctxt->doc  = refNode->doc;
            if (ctxt->node != old_node && ctxt->node != NULL)
                registered_ns = _domXPathCtxtRegisterNS(ctxt, ctxt->node);
        }
        if (to_bool) {
            int val = xmlXPathCompiledEvalToBoolean(comp, ctxt);
            rv = xmlXPathNewBoolean(val);
        } else {
            rv = xmlXPathCompiledEval(comp, ctxt);
        }

        ctxt->node = old_node;
        ctxt->doc = old_doc;
        if (registered_ns) {
            _domXPathCtxtRemoveNS(ctxt, registered_ns);
            xmlFree(registered_ns);
        }
    }
    return _domVetXPathObject(rv);
}

DLLEXPORT xmlNodeSetPtr
domXPathSelectCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode) {
    return _domSelect(domXPathFindCtxt(ctxt, comp, refNode, 0));
}


