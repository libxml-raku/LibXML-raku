#include "xml6.h"
#include "xml6_node.h"
#include "xml6_ref.h"
#include "libxml/xmlsave.h"
#include "libxml/xpath.h"
#include "libxml/c14n.h"

DLLEXPORT void xml6_node_add_reference(xmlNodePtr self) {
    xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_node_remove_reference(xmlNodePtr self) {
    return xml6_ref_remove( &(self->_private), "node", (void*) self);
}

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr self) {
    xmlNodePtr node = self;

    while (node && node->parent) {
        node = node->parent;
    }

    if (node && node->type == XML_ENTITY_DECL) {
        xmlDocPtr doc = node->doc;
        const xmlChar* name = node->name;
        if (doc != NULL) {
            if ((doc->intSubset != NULL
                 && xmlHashLookup(doc->intSubset->entities, name) == node)
                ||
                (doc->extSubset != NULL
                 && xmlHashLookup(doc->extSubset->entities, name) == node)) {
                node = (xmlNodePtr)doc;
            }
        }
    }

    if (node && node->prev) {
        // Unexpected, if we're using the DOM properly. The node should
        // either be unlinked, or parented to a unique xmlDoc/xmlDocFrag.
        fail(self, "root node has multiple elements");
    }

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr node, int keep_blanks) {
    node = node->children;
    if (keep_blanks == 0) {
        while (node && xmlIsBlankNode(node)) {
            node = node->next;
        }
    }

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr node, int keep_blanks) {
    do {
        node = node->next;
    } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr node, int keep_blanks) {
    do {
        node = node->prev;
    } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

    return node;
}

DLLEXPORT void xml6_node_set_doc(xmlNodePtr self, xmlDocPtr doc) {
    if (self == NULL) xml6_fail("unable to update null node");
    if (self->doc && self->doc != doc) xml6_warn("possible memory leak in setting node->doc");

    self->doc = doc;
}

DLLEXPORT void xml6_node_set_ns(xmlNodePtr self, xmlNsPtr ns) {
    if (self == NULL) xml6_fail("unable to update null node");
    if (self->ns && self->ns != ns) xml6_warn("possible memory leak in setting node->ns");

    self->ns = ns;
}

DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr self, xmlNsPtr ns) {
    if (self == NULL) xml6_fail("unable to update null node");
    if (self->nsDef && self->nsDef != ns) xml6_warn("possible memory leak in setting node->nsDef");

    self->nsDef = ns;
}

DLLEXPORT void xml6_node_set_content(xmlNodePtr self, xmlChar* new_content) {
    if (self == NULL) xml6_fail("unable to update null node");
    if (self->content) xmlFree(self->content);

    self->content = xmlStrdup((const xmlChar *) new_content);
}

DLLEXPORT xmlChar* xml6_node_to_buf(xmlNodePtr self, int options, size_t* len, char* encoding) {
    xmlChar* rv = NULL;

    if (!encoding || !encoding[0]) encoding = "UTF-8";
    if (len != NULL) *len = 0;
    if (self) {
        xmlBufferPtr buffer = xmlBufferCreate();
        xmlSaveCtxtPtr save_ctx = xmlSaveToBuffer(buffer, encoding, options);
        int stat = xmlSaveTree(save_ctx, self);

        xmlSaveClose(save_ctx);

        if (stat >= 0) {
            rv = buffer->content;
            buffer->content = NULL;
            if (len != NULL) {
                *len = buffer->use;
            }
        }
        xmlBufferFree(buffer);
    }

    return rv;
}

DLLEXPORT xmlChar* xml6_node_to_str(xmlNodePtr self, int options) {
    return xml6_node_to_buf(self, options, NULL, "UTF-8");
}



static void
_configure_namespaces( xmlXPathContextPtr ctxt ) {
    xmlNodePtr node = ctxt->node;

    if (ctxt->namespaces != NULL) {
        xmlFree( ctxt->namespaces );
        ctxt->namespaces = NULL;
    }
    if (node != NULL) {
        if (node->type == XML_DOCUMENT_NODE) {
            ctxt->namespaces = xmlGetNsList( node->doc,
                                             xmlDocGetRootElement( node->doc ) );
        } else {
            ctxt->namespaces = xmlGetNsList(node->doc, node);
        }
        ctxt->nsNr = 0;
        if (ctxt->namespaces != NULL) {
	  int cur=0;
	  xmlNsPtr ns;
	  /* we now walk through the list and
	     drop every ns that was declared via registration */
	  while (ctxt->namespaces[cur] != NULL) {
	    ns = ctxt->namespaces[cur];
	    if (ns->prefix==NULL ||
		xmlHashLookup(ctxt->nsHash, ns->prefix) != NULL) {
	      /* drop it */
	      ctxt->namespaces[cur]=NULL;
	    } else {
	      if (cur != ctxt->nsNr) {
		/* move the item to the new tail */
		ctxt->namespaces[ctxt->nsNr]=ns;
		ctxt->namespaces[cur]=NULL;
	      }
	      ctxt->nsNr++;
	    }
	    cur++;
	  }
        }
    }
}

DLLEXPORT xmlChar* xml6_node_to_str_C14N(xmlNodePtr self, int comments, int exclusive, xmlChar* nodepath, xmlChar** inc_prefix_list, xmlXPathContextPtr xpath_ctxt) {
    xmlChar *rv                   = NULL;
    xmlXPathObjectPtr xpath_res   = NULL;
    xmlNodeSetPtr nodelist        = NULL;
    xmlNodePtr refNode            = self;
    xmlXPathContextPtr child_ctxt = xpath_ctxt;
    int stat;

    /* due to how c14n is implemented, the nodeset it receives must
       include child nodes; ie, child nodes aren't assumed to be rendered.
       so we use an xpath expression to find all of the child nodes.
    */
    if ( self->doc == NULL ) {
        fail(self, "Node passed to toStringC14N must be part of a document");
    }

    refNode = self;

    if ( nodepath != NULL && xmlStrlen( nodepath ) == 0 ) {
        nodepath = NULL;
    }

    if ( nodepath == NULL
         && self->type != XML_DOCUMENT_NODE
         && self->type != XML_HTML_DOCUMENT_NODE
         && self->type != XML_DOCB_DOCUMENT_NODE
        ) {
        if (comments)
            nodepath = (xmlChar *) "(. | .//node() | .//@* | .//namespace::*)";
        else
            nodepath = (xmlChar *) "(. | .//node() | .//@* | .//namespace::*)[not(self::comment())]";
    }

    if ( nodepath != NULL ) {
        if ( self->type == XML_DOCUMENT_NODE
             || self->type == XML_HTML_DOCUMENT_NODE
             || self->type == XML_DOCB_DOCUMENT_NODE ) {
            refNode = xmlDocGetRootElement( self->doc );
        }

        if (!child_ctxt) {
            child_ctxt = xmlXPathNewContext(self->doc);
        }

        child_ctxt->node = self;
        _configure_namespaces(child_ctxt);

        xpath_res = xmlXPathEval(nodepath, child_ctxt);
        if (child_ctxt->namespaces != NULL) {
            xmlFree( child_ctxt->namespaces );
            child_ctxt->namespaces = NULL;
        }
        if (!xpath_ctxt) xmlXPathFreeContext(child_ctxt);

        if (xpath_res == NULL) {
            fail(self, "failed to compile xpath expression");
        }

        nodelist = xpath_res->nodesetval;
        if ( nodelist == NULL ) {
            xmlXPathFreeObject(xpath_res);
            fail(self, "cannot canonize empty nodeset!" );
        }

    }
    xml6_warn("");
    stat = xmlC14NDocDumpMemory( self->doc,
                                 nodelist,
                                 exclusive,
                                 inc_prefix_list,
                                 comments,
                                 &rv );
    if ( xpath_res ) xmlXPathFreeObject(xpath_res);

    if (stat < 0) {
        char msg[80];
        sprintf(msg, "C14N serialization returned error status: %d", stat);
        fail(self, msg);
    }

    return rv;
}
