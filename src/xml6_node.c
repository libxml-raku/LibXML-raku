#include "xml6.h"
#include "xml6_node.h"
#include "xml6_ref.h"
#include "libxml/xpathInternals.h"
#include "libxml/xmlsave.h"
#include "libxml/c14n.h"
#include <assert.h>

DLLEXPORT void xml6_node_add_reference(xmlNodePtr self) {
    assert(self != NULL);
    assert(self->type != XML_NAMESPACE_DECL);
    xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_node_remove_reference(xmlNodePtr self) {
    assert(self != NULL);
    assert(self->type != XML_NAMESPACE_DECL);
    if (self->_private == NULL) {
        /* unexpected; print some extra debugging */
        fprintf(stderr, __FILE__ ":%d %p type=%d name='%s'\n", __LINE__, self, self->type, (self->name ? (char*) self->name : "(null)"));
    }
    return xml6_ref_remove( &(self->_private), "node", (void*) self);
}

DLLEXPORT int xml6_node_lock(xmlNodePtr self) {
    assert(self != NULL);
    return xml6_ref_lock( &(self->_private));
}

DLLEXPORT int xml6_node_unlock(xmlNodePtr self) {
    assert(self != NULL);
    return xml6_ref_unlock( &(self->_private));
}

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr self) {
    xmlNodePtr node = self;
    assert(node != NULL);

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
        xml6_fail(self, "root node has multiple elements");
    }

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr node, int keep_blanks) {
    assert(node != NULL);
    node = node->children;
    if (keep_blanks == 0) {
        while (node && xmlIsBlankNode(node)) {
            node = node->next;
        }
    }

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr node, int keep_blanks) {
    assert(node != NULL);
    do {
        node = node->next;
    } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

    return node;
}

DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr node, int keep_blanks) {
    assert(node != NULL);
    do {
        node = node->prev;
    } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

    return node;
}

DLLEXPORT void xml6_node_set_doc(xmlNodePtr self, xmlDocPtr doc) {
    assert(self != NULL);
    if (self->doc && self->doc != doc) xml6_warn("possible memory leak in setting node->doc");

    self->doc = doc;
}

DLLEXPORT void xml6_node_set_ns(xmlNodePtr self, xmlNsPtr ns) {
    assert(self != NULL);
    if (self->ns && self->ns != ns) xml6_warn("possible memory leak in setting node->ns");

    self->ns = ns;
}

DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr self, xmlNsPtr ns) {
    assert(self != NULL);
    if (self->nsDef && self->nsDef != ns) xml6_warn("possible memory leak in setting node->nsDef");

    self->nsDef = ns;
}

DLLEXPORT void xml6_node_set_content(xmlNodePtr self, xmlChar* new_content) {
    assert(self != NULL);
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


DLLEXPORT xmlChar* xml6_node_to_str_C14N(xmlNodePtr self, int comments,  xmlC14NMode mode, xmlChar** inc_prefix_list, xmlNodeSetPtr nodelist) {
    xmlChar *rv = NULL;
    int stat;

    if ( self->doc == NULL ) {
        xml6_fail(self, "Node passed to toStringC14N must be part of a document");
    }

    stat = xmlC14NDocDumpMemory( self->doc,
                                 nodelist,
                                 mode,
                                 inc_prefix_list,
                                 comments,
                                 &rv );

    if (stat < 0) {
        char msg[80];
        sprintf(msg, "C14N serialization returned error status: %d", stat);
        xml6_fail(self, msg);
    }

    return rv;
}

