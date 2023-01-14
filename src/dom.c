/* $Id$
 *
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2001-2003 AxKit.com Ltd., 2002-2006 Christian Glahn, 2006-2009 Petr Pajas
 * Ported from Perl 5 to Raku by David Warring
 */

#include "dom.h"
#include "domXPath.h"
#include "xml6.h"
#include "xml6_gbl.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

#define warn(string) {fprintf(stderr, __FILE__ "%d: %s\n", __LINE__, (string));}

DLLEXPORT void
domClearPSVIInList(xmlNodePtr list);

static int _domIsDoc(xmlNodePtr node) {
    return(node->type == XML_DOCUMENT_NODE
           || node->type == XML_HTML_DOCUMENT_NODE
#ifdef LIBXML_DOCB_ENABLED
           || node->type == XML_DOCB_DOCUMENT_NODE
#endif
        );
}

DLLEXPORT void
domClearPSVI(xmlNodePtr tree) {
    xmlAttrPtr prop;

    if (tree == NULL)
        return;
    if (tree->type == XML_ELEMENT_NODE) {
        tree->psvi = NULL;
        prop = tree->properties;
        while (prop != NULL) {
            if (tree->type == XML_ATTRIBUTE_NODE)
                ((xmlAttrPtr) prop)->psvi = NULL;
            domClearPSVIInList(prop->children);
            prop = prop->next;
        }
    } else if (_domIsDoc(tree)) {
        ((xmlDocPtr) tree)->psvi = NULL;
    }
    if (tree->children != NULL)
        domClearPSVIInList(tree->children);
}

DLLEXPORT void
domClearPSVIInList(xmlNodePtr list) {
    xmlNodePtr cur;

    if (list == NULL)
        return;
    cur = list;
    while (cur != NULL) {
        domClearPSVI(cur);
        cur = cur->next;
    }
}

static void
_domAddNsDef(xmlNodePtr tree, xmlNsPtr ns) {
    xmlNsPtr i = tree->nsDef;
    while(i != NULL && i != ns)
        i = i->next;
    if( i == NULL ) {
        ns->next = tree->nsDef;
        tree->nsDef = ns;
    }
}

static int
_domRemoveNsDef(xmlNodePtr tree, xmlNsPtr ns) {
    xmlNsPtr i = tree->nsDef;

    if( ns == tree->nsDef ) {
        tree->nsDef = tree->nsDef->next;
        ns->next = NULL;
        return(1);
    }
    while( i != NULL ) {
        if( i->next == ns ) {
            i->next = ns->next;
            ns->next = NULL;
            return(1);
        }
        i = i->next;
    }
    return(0);
}

/* ns->next must be NULL, or bad things could happen */
static xmlNsPtr
_domAddNsChain(xmlNsPtr c, xmlNsPtr ns) {
    if( c == NULL )
        return(ns);
    else {
        xmlNsPtr i = c;
        while(i != NULL && i != ns)
            i = i->next;
        if(i == NULL) {
            ns->next = c;
            return(ns);
        }
    }
    return(c);
}

/* We need to be smarter with attributes, because the declaration is on the parent element */
static void
_domReconcileNsAttr(xmlAttrPtr attr, xmlNsPtr * unused) {
    xmlNodePtr tree = attr->parent;
    if (tree == NULL)
        return;
    if( attr->ns != NULL ) {
        xmlNsPtr ns;
        if ((attr->ns->prefix != NULL) &&
            (xmlStrEqual(attr->ns->prefix, BAD_CAST "xml"))) {
            /* prefix 'xml' has no visible declaration */
            ns = xmlSearchNsByHref(tree->doc, tree, XML_XML_NAMESPACE);
            attr->ns = ns;
            return;
        } else {
            ns = xmlSearchNs( tree->doc, tree->parent, attr->ns->prefix );
        }
        if( ns != NULL && ns->href != NULL && attr->ns->href != NULL &&
            xmlStrcmp(ns->href,attr->ns->href) == 0 ) {
            /* Remove the declaration from the element */
            if( _domRemoveNsDef(tree, attr->ns) )
                /* Queue up this namespace for freeing */
                *unused = _domAddNsChain(*unused, attr->ns);

            /* Replace the namespace with the one found */
            attr->ns = ns;
        }
        else {
            /* If the declaration is here, we don't need to do anything */
            if( _domRemoveNsDef(tree, attr->ns) )
                _domAddNsDef(tree, attr->ns);
            else {
                /* Replace/Add the namespace declaration on the element */
                attr->ns = xmlCopyNamespace(attr->ns);
                if (attr->ns) {
                    _domAddNsDef(tree, attr->ns);
                }
            }
        }
    }
}

/**
 * Name: _domReconcileNs
 * Synopsis: void _domReconcileNs( xmlNodePtr tree );
 * @tree: the tree to reconcile
 *
 * Reconciles namespacing on a tree by removing declarations
 * of element and attribute namespaces that are already
 * declared in the scope of the corresponding node.
 **/

static void
_domReconcileNs(xmlNodePtr tree, xmlNsPtr * unused) {
    if( tree->ns != NULL
        && ((tree->type == XML_ELEMENT_NODE)
            || (tree->type == XML_ATTRIBUTE_NODE))) {
        xmlNsPtr ns = xmlSearchNs( tree->doc, tree->parent, tree->ns->prefix );
        if( ns != NULL && ns->href != NULL && tree->ns->href != NULL &&
            xmlStrcmp(ns->href,tree->ns->href) == 0 ) {
            /* Remove the declaration (if present) */
            if( _domRemoveNsDef(tree, tree->ns) )
                /* Queue the namespace for freeing */
                *unused = _domAddNsChain(*unused, tree->ns);

            /* Replace the namespace with the one found */
            tree->ns = ns;
        }
        else {
            /* If the declaration is here, we don't need to do anything */
            if( _domRemoveNsDef(tree, tree->ns) ) {
                _domAddNsDef(tree, tree->ns);
            }
            else {
                /* Restart the namespace at this point */
                tree->ns = xmlCopyNamespace(tree->ns);
                _domAddNsDef(tree, tree->ns);
            }
        }
    }
    /* Fix attribute namespacing */
    if( tree->type == XML_ELEMENT_NODE ) {
        xmlElementPtr ele = (xmlElementPtr) tree;
        /* attributes is set to xmlAttributePtr,
           but is an xmlAttrPtr??? */
        xmlAttrPtr attr = (xmlAttrPtr) ele->attributes;
        while( attr != NULL ) {
            _domReconcileNsAttr(attr, unused);
            attr = attr->next;
        }
    }
    {
        /* Recurse through all child nodes */
        xmlNodePtr child = tree->children;
        while( child != NULL ) {
            _domReconcileNs(child, unused);
            child = child->next;
        }
    }
}

static void _domRemoveEntityRefs(xmlNodePtr self, xmlDtdPtr dtd) {
    xmlAttrPtr attr;
    xmlNodePtr cur;
    if (self == NULL) return;
    if (self->type == XML_ENTITY_REF_NODE) {
        if (self->children != NULL && self->children->parent == (xmlNodePtr) dtd) {
            self->children = NULL;
        }
    }
    else {
        for (attr = self->properties; attr != NULL; attr = attr->next) {
            for (cur = attr->children; cur != NULL; cur = cur->next) {
                _domRemoveEntityRefs(cur, dtd);
            }
        }
        for (cur = self->children; cur != NULL; cur = cur->next) {
            _domRemoveEntityRefs(cur, dtd);
        }
    }
}

DLLEXPORT void domUnlinkNode(xmlNodePtr self) {
    xmlUnlinkNode(self);

    if (self != NULL && self->type == XML_DTD_NODE) {
        xmlDtdPtr dtd = (xmlDtdPtr)self;
        if (dtd->doc != NULL && dtd->entities != NULL) {
            xmlNodePtr root = xmlDocGetRootElement(dtd->doc);
            _domRemoveEntityRefs(root, dtd);
        }
    }
}

DLLEXPORT void
domReconcileNs(xmlNodePtr tree) {
    xmlNsPtr unused = NULL;
    _domReconcileNs(tree, &unused);
    if( unused != NULL ) {
        // sanity check for externally referenced namespaces. shouldn't really happen
        int is_referenced = 0;
        xmlNsPtr cur = unused;
        while (cur && is_referenced == 0) {
            is_referenced = (cur->_private != NULL);
            if (is_referenced != 0) {
                xml6_warn("namespace node is inuse or private");
            }
            cur = cur->next;
        }

        if (is_referenced == 0) {    
            xmlFreeNsList(unused);
        }
    }
}

static xmlNodePtr
_domExtractFrag(xmlNodePtr frag) {
    xmlNodePtr fraglist = frag->children;
    xmlNodePtr cur = fraglist;
    // detach fragment list
    frag->children = frag->last = NULL;
    while ( cur ){
        cur->parent = NULL;
        cur = cur->next;
    }

    return fraglist;
}

DLLEXPORT xmlDtdPtr
domGetInternalSubset(xmlDocPtr self) {
    return xmlGetIntSubset(self);
}

DLLEXPORT xmlDtdPtr
domGetExternalSubset(xmlDocPtr self) {
    return self->extSubset;
}


DLLEXPORT xmlDtdPtr
domSetInternalSubset(xmlDocPtr self, xmlDtdPtr dtd) {
    xmlDtdPtr int_dtd = NULL;

    assert(self != NULL);

    int_dtd = domGetInternalSubset(self);

    if (int_dtd == dtd) {
        return dtd;
    }

    if (int_dtd != NULL) {
        domReleaseNode((xmlNodePtr) int_dtd);
    }

    if (dtd != NULL) {
        domUnlinkNode((xmlNodePtr)dtd);
        if (dtd->doc == NULL) {
            xmlSetTreeDoc( (xmlNodePtr) dtd, self );
        } else if ( dtd->doc != self ) {
            XML6_FAIL(self, "moving DTDs between documents is not supported.");
        }

        if (self->children == NULL)
            xmlAddChild((xmlNodePtr) self, (xmlNodePtr) dtd);
        else
            xmlAddPrevSibling(self->children, (xmlNodePtr) dtd);
    }
    self->intSubset = dtd;

    return dtd;
}

DLLEXPORT xmlDtdPtr
domSetExternalSubset(xmlDocPtr self, xmlDtdPtr dtd) {
    xmlDtdPtr ext_dtd = NULL;

    assert(self != NULL);

    ext_dtd = domGetExternalSubset(self);

    if (ext_dtd == dtd) {
        return dtd;
    }

    if (ext_dtd != NULL) {
        domReleaseNode((xmlNodePtr) ext_dtd);
    }

    if (dtd != NULL) {
        domUnlinkNode( (xmlNodePtr) dtd);
        if ( dtd->doc == NULL ) {
            xmlSetTreeDoc( (xmlNodePtr) dtd, self );
        } else if (dtd->doc != self) {
            XML6_FAIL(self, "moving DTDs between documents is not supported");
        }
    }

    self->extSubset = dtd;
    return dtd;
}

DLLEXPORT xmlEntityPtr
domGetEntityFromDtd(xmlDtdPtr dtd, xmlChar *name) {
    xmlEntitiesTablePtr table;

    if((dtd != NULL) && (dtd->entities != NULL)) {
	table = (xmlEntitiesTablePtr) dtd->entities;
	return((xmlEntityPtr) xmlHashLookup(table, name));
    }
    return(NULL);
}

DLLEXPORT xmlEntityPtr
domGetParameterEntityFromDtd(xmlDtdPtr dtd, xmlChar *name) {
    xmlEntitiesTablePtr table;

    if ((dtd != NULL) && (dtd->pentities != NULL)) {
	table = (xmlEntitiesTablePtr) dtd->pentities;
	return((xmlEntityPtr) xmlHashLookup(table, name));
    }
    return(NULL);
}


static xmlNodePtr
_domAssimulate(xmlNodePtr head, xmlNodePtr tail) {
    xmlNodePtr cur = head;
    while ( cur ) {
        /* we must reconcile all nodes in the fragment */
        if (cur->type == XML_DTD_NODE) {
            if (_domIsDoc(cur->parent) == 0) {
                xml6_warn("non-root DTD node found");
                domUnlinkNode(cur);
            }
            if (cur->doc && domGetExternalSubset(cur->doc) != (xmlDtdPtr)cur) {
                domSetInternalSubset(cur->doc, (xmlDtdPtr) cur);
            }
        }
        else {
            domReconcileNs(cur);
        }
        if ( !tail || !cur || cur == tail ) {
            break;
        }
        cur = cur->next;
    }

    return head;
}

/**
 * internal helper: insert node to nodelist
 * synopsis: xmlNodePtr insert_node_to_nodelist( leader, insertnode, followup );
 * while leader and followup are already list nodes. both may be NULL
 * if leader is null the parents children will be reset
 * if followup is null the parent last will be reset.
 * leader and followup has to be followups in the nodelist!!!
 * the function returns the node inserted. if a fragment was inserted,
 * the first node of the list will returned
 *
 **/
static xmlNodePtr
_domAddNodeToList(xmlNodePtr cur, xmlNodePtr leader, xmlNodePtr followup, xmlNodePtr *ptail) {
    xmlNodePtr head = NULL, tail = NULL, p = NULL, n = NULL;
    assert(ptail != NULL);

    if (cur == NULL) {
        *ptail = NULL;
        return NULL;
    }

    head = tail = cur;
    if ( leader ) {
        p = leader->parent;
    }
    else if ( followup ) {
        p = followup->parent;
    }
    else {
        *ptail = NULL;
        return NULL; /* can't insert */
    }

    if (leader && followup && p != followup->parent) {
        warn("_domAddNodeToList(cur, prev, next, &frag) - 'prev' and 'next' have different parents");
    }

    if ( cur->type == XML_DOCUMENT_FRAG_NODE ) {
        head = _domExtractFrag(cur);

        n = head;
        while ( n ){
            n->parent = p;
            n->doc = p->doc;
            tail = n;
            n = n->next;
        }
    }
    else {
        cur->parent = p;
    }

    if (head && tail && head != leader) {
        if ( leader ) {
            leader->next = head;
            head->prev = leader;
        }
        else if ( p ) {
            p->children = head;
        }

        if ( followup ) {
            followup->prev = tail;
            tail->next = followup;
        }
        else if ( p ) {
            p->last = tail;
        }
    }

    *ptail = tail;
    return head;
}

static xmlNodePtr
_domSetDtd(xmlDocPtr doc, xmlDtdPtr dtd, xmlNodePtr old) {
    xmlDtdPtr ext_dtd = domGetExternalSubset(doc);
    int replace_external = (old && old->type == XML_DTD_NODE ? (xmlDtdPtr)old : dtd) == ext_dtd;

    if (doc == NULL) XML6_FAIL(dtd, "DTD is not associated with a document");
    if (_domIsDoc((xmlNodePtr)doc) == 0 || (dtd != NULL && dtd->type != XML_DTD_NODE)) {
        XML6_FAIL((xmlNodePtr)dtd, "SetDtd: HIERARCHY_REQUEST_ERR");
    }

    if (old) domUnlinkNode(old);

    if (dtd != (xmlDtdPtr)old) {
        if (replace_external) {
            dtd = domSetExternalSubset(doc, dtd);
        }
        else {
            dtd = domSetInternalSubset(doc, dtd);
        }
    }

    return (xmlNodePtr) dtd;
}

/**
 * domIsParent tests, if testnode is parent of the reference
 * node. this test is very important to avoid circular constructs in
 * trees. if the ref is a parent of the cur node the
 * function returns 1 (TRUE), otherwise 0 (FALSE).
 **/
DLLEXPORT int
domIsParent( xmlNodePtr cur, xmlNodePtr refNode ) {
    xmlNodePtr ancestor = NULL;

    if ( cur == NULL || refNode == NULL) return 0;
    if (refNode == cur) return 1;
    if ( cur->doc != refNode->doc
         || refNode->children == NULL
         || cur->parent == (xmlNodePtr)cur->doc
         || cur->parent == NULL ) {
        return 0;
    }

    if (_domIsDoc(refNode)) {
        return 1;
    }

    ancestor = cur;
    while ( ancestor && (xmlDocPtr) ancestor != cur->doc ) {
        if( ancestor == refNode ) {
            return 1;
        }
        ancestor = ancestor->parent;
    }

    return 0;
}

DLLEXPORT int
domTestHierarchy(xmlNodePtr cur, xmlNodePtr refNode) {
    if ( !refNode || !cur ) {
        return 0;
    }
    if (cur->type == XML_ATTRIBUTE_NODE) {
        switch ( refNode->type ){
        case XML_TEXT_NODE:
        case XML_ENTITY_REF_NODE:
            return 1;
            break;
        default:
            return 0;
            break;
        }
    }

    switch ( refNode->type ){
    case XML_ATTRIBUTE_NODE:
    case XML_DOCUMENT_NODE:
    case XML_ATTRIBUTE_DECL:
    case XML_ENTITY_DECL:
    case XML_ELEMENT_DECL:
    case XML_NOTATION_NODE:
        return 0;
        break;
    default:
        break;
    }

    if ( domIsParent( cur, refNode ) ) {
        return 0;
    }

    return 1;
}

DLLEXPORT int
domTestDocument(xmlNodePtr cur, xmlNodePtr refNode) {
    if ( _domIsDoc(cur) ) {
        switch ( refNode->type ) {
        case XML_ATTRIBUTE_NODE:
        case XML_ELEMENT_NODE:
        case XML_ENTITY_NODE:
        case XML_ENTITY_REF_NODE:
        case XML_TEXT_NODE:
        case XML_CDATA_SECTION_NODE:
        case XML_NAMESPACE_DECL:
            return 0;
            break;
        default:
            break;
        }
    }
    return 1;
}

static void _domScanEntry(void* value, int* refs, xmlChar* key) {
    if (value != NULL && ((xmlNodePtr)value)->_private != NULL) {
        (*refs)++;
    }
}

static int
_domScanHashForRefs(xmlHashTablePtr self) {
    int refs = 0;
    if (self != NULL) {
        xmlHashScan(self, (xmlHashScanner)_domScanEntry, (void*) &refs);
    }
    return refs;
}

// Determine if there's any API references to a node or its descendants
static int
_domPeerIsReferenced(xmlNodePtr self) {
    assert(self != NULL);

    // cheap checks
    if (self->type == XML_NAMESPACE_DECL) {
        return ((xmlNsPtr) self)->_private != NULL;
    }
    else {
        if (self->_private != NULL) {
            return 1;
        }
    }

    if (self->type == XML_ELEMENT_NODE) {
        // scan element attributes
        if (domNodeIsReferenced((xmlNodePtr)self->properties)) {
            return 1;
        }
    }
    else if (self->type == XML_DTD_NODE) {
        xmlDtdPtr dtd = (xmlDtdPtr)self;
        if (_domScanHashForRefs(dtd->elements)
            || _domScanHashForRefs(dtd->attributes)
            || _domScanHashForRefs(dtd->entities)) {
            return 1;
        }
    }
    else if (_domIsDoc(self)) {
        // check external DtD
        xmlDtdPtr dtd = ((xmlDocPtr) self)->extSubset;
        if (dtd != NULL && _domPeerIsReferenced((xmlNodePtr)dtd)) {
            return 1;
        }
    }

    if (self->type == XML_ENTITY_DECL) {
        xmlEntityPtr ent = (xmlEntityPtr) self;
        if (ent->etype == XML_INTERNAL_PREDEFINED_ENTITY) {
            // predefined entities are static. don't GC
            return 1;
        }
    }
    else if (self->type != XML_ENTITY_REF_NODE) {
        // scan children
        if (domNodeIsReferenced(self->children)) {
            return 1;
        }
    }

    return 0;
}

// Determine if there's any API references in a node or its siblings
DLLEXPORT int
domNodeIsReferenced(xmlNodePtr cur) {
    if (cur == NULL) return 0;
    while (cur->prev) cur = cur->prev;
    while (cur) {
        if (_domPeerIsReferenced(cur)) return 1;
        cur = cur->next;
    }
    return 0;
}

DLLEXPORT void
domReleaseNode( xmlNodePtr node ) {
    domUnlinkNode(node);

    if ( domNodeIsReferenced(node) == 0 ) {
        node->_private = xml6_ref_freed();
        xmlFreeNode(node);
    }
}

DLLEXPORT xmlNodePtr
domImportNode( xmlDocPtr doc, xmlNodePtr node, int move, int reconcileNS ) {
    xmlNodePtr imported_node = node;
    if ( move ) {
        imported_node = node;
        domUnlinkNode( node );
    }
    else if (node != NULL) {
        if ( node->type == XML_DTD_NODE ) {
            imported_node = (xmlNodePtr) xmlCopyDtd((xmlDtdPtr) node);
        }
        else {
            imported_node = xmlDocCopyNode( node, doc, 1 );
        }
    }


    /* tell all children about the new boss */
    if ( node && node->doc != doc ) {
        xmlSetTreeDoc(imported_node, doc);
    }

    if ( reconcileNS && doc && imported_node
         && imported_node->type != XML_ENTITY_REF_NODE ) {
        domReconcileNs(imported_node);
    }

    return imported_node;
}

// DOM compliant.
DLLEXPORT const xmlChar*
domGetNodeName(xmlNodePtr node) {
    const xmlChar* prefix = NULL;
    const xmlChar* name   = NULL;

    if ( node == NULL ) {
        return NULL;
    }

    switch ( node->type ) {
    case XML_XINCLUDE_START :
    case XML_XINCLUDE_END :
    case XML_ENTITY_REF_NODE :
    case XML_ENTITY_NODE :
    case XML_DTD_NODE :
    case XML_ENTITY_DECL :
    case XML_DOCUMENT_TYPE_NODE :
    case XML_NOTATION_NODE :
    case XML_NAMESPACE_DECL :
        name = node->name;
        break;

    case XML_COMMENT_NODE :
        name = (const xmlChar*) "#comment";
        break;

    case XML_CDATA_SECTION_NODE :
        name = (const xmlChar*) "#cdata-section";
        break;

    case XML_TEXT_NODE :
        name = (const xmlChar*) "#text";
        break;

    case XML_DOCUMENT_NODE :
    case XML_HTML_DOCUMENT_NODE :
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE :
#endif
        name = (const xmlChar*) "#document";
        break;

    case XML_DOCUMENT_FRAG_NODE :
        name = (const xmlChar*) "#document-fragment";
        break;

    case XML_PI_NODE :
    case XML_ELEMENT_NODE :
    case XML_ATTRIBUTE_NODE :
        if ( node->ns != NULL ) {
            prefix = node->ns->prefix;
        }
        name = node->name;
        break;

    case XML_ELEMENT_DECL :
        prefix = ((xmlElementPtr) node)->prefix;
        name = node->name;
        break;

    case XML_ATTRIBUTE_DECL :
        prefix = ((xmlAttributePtr) node)->prefix;
        name = node->name;
        break;
    }

    if ( prefix != NULL ) {
        int prefix_len = strlen((char*)prefix);
        char* buf = malloc(strlen((char*)prefix) + strlen((char*)name) + 3);
        strcpy(buf, (char*)prefix);
        buf[prefix_len] = ':';
        strcpy(buf + prefix_len + 1, (char*)name);
        name = xml6_gbl_cache((xmlChar*)buf);
    }

    return name;
}

static const xmlChar* _domPrepend(const xmlChar* name, char pfx) {
    int buf_len = xmlStrlen(name) + 2;
    xmlChar* buf = malloc(buf_len);
    buf[0] = pfx;
    strncpy((char*)buf+1, (char*)name, buf_len-1);
    return xml6_gbl_cache(buf);
}

// Returns a name that can be used in an XPath filter expression
DLLEXPORT const xmlChar*
domGetXPathKey(xmlNodePtr node) {
    const xmlChar* name = NULL;

    switch ((int)node->type) {
        case XML_COMMENT_NODE :
            name = (xmlChar*) "comment()";
            break;
        case XML_CDATA_SECTION_NODE :
        case XML_TEXT_NODE :
            name = (xmlChar*) "text()";
            break;
        case XML_NAMESPACE_DECL :
            name = (xmlChar*) "namespace()";
            break;
        case XML_DOCUMENT_NODE :
        case XML_HTML_DOCUMENT_NODE :
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE :
#endif
        case XML_DOCUMENT_FRAG_NODE :
            name = (xmlChar*) "document()";
            break;
        case XML_PI_NODE :
            name = (xmlChar*) "processing-instruction()";
            break;
        case XML_ENTITY_REF_NODE :
            /* not searchable via xpath */
            break;
        default :
            name = domGetNodeName(node);
            if (node->type == XML_ATTRIBUTE_NODE) {
                name = _domPrepend(name, '@');
            }
        break;
    }
return (xmlChar*)name;
}

// Returns a name tailored for AST construction
DLLEXPORT const xmlChar*
domGetASTKey(xmlNodePtr node) {
    const xmlChar* name = NULL;

    switch (node->type) {
        case XML_DOCUMENT_NODE :
            name = (xmlChar*) "#xml";
            break;
        case XML_HTML_DOCUMENT_NODE :
            name = (xmlChar*) "#html";
            break;
#ifdef LIBXML_DOCB_ENABLED
        case XML_DOCB_DOCUMENT_NODE :
            name = (xmlChar*) "#docb";
            break;
#endif
        case XML_DOCUMENT_FRAG_NODE :
            name = (xmlChar*) "#fragment";
            break;
        case XML_CDATA_SECTION_NODE :
            name = (xmlChar*) "#cdata";
            break;
        default :
            name = domGetNodeName(node);
            if (node->type == XML_PI_NODE) {
                name = _domPrepend(name, '?');
            }
            else if (node->type == XML_ENTITY_REF_NODE) {
                name = _domPrepend(name, '&');
            }
    }
    return name;
}

DLLEXPORT void
domSetNodeName(xmlNodePtr self , xmlChar *string) {
    xmlChar* localname;
    xmlChar* prefix;

    if (self == NULL || string == NULL || *string == 0)
        return;

    if ((self->type == XML_PI_NODE && *string == '?')
        || (self->type == XML_ENTITY_REF_NODE && *string == '&')) {
        // skip leading '?' or '&'
        string++;
    }

    if( ( self->type == XML_ELEMENT_NODE
          || self->type == XML_ATTRIBUTE_NODE
          || self->type == XML_PI_NODE)
        && self->ns ){
        localname = xmlSplitQName2(string, &prefix);
        if ( localname == NULL ) {
            localname = xmlStrdup( string );
        }
        xmlNodeSetName(self, localname );
        xmlFree(localname);
        xmlFree(prefix);
    }
    else {
        xmlNodeSetName(self, string );
    }
}

/**
 * Name: domAppendChild
 * Synopsis: xmlNodePtr domAppendChild( xmlNodePtr par, xmlNodePtr newCld );
 * @par: the node to append to
 * @newCld: the node to append
 *
 * Returns newCld on success otherwise NULL
 * The function will unbind newCld first if necessary. As well the
 * function will fail, if par or newCld is a Attribute Node OR if newCld
 * is a parent of par.
 *
 * If newCld belongs to a different DOM the node will be imported
 * implicit before it gets appended.
 **/
DLLEXPORT xmlNodePtr
domAppendChild( xmlNodePtr self,
                xmlNodePtr newChild ){
    xmlNodePtr head = newChild;
    xmlNodePtr tail = newChild;

    if ( self == NULL) {
        return newChild;
    }

    if ( newChild->type == XML_DTD_NODE ) {
        return _domSetDtd((xmlDocPtr)self, (xmlDtdPtr)newChild, NULL);
    }
    if (self->type == XML_ELEMENT_NODE) {
        if (newChild->type == XML_ATTRIBUTE_NODE) {
            return (xmlNodePtr)domSetAttributeNodeNS(self, (xmlAttrPtr) newChild );
        }
        if (newChild->type == XML_NAMESPACE_DECL) {
            xmlNsPtr ns = (xmlNsPtr) newChild;
            return (xmlNodePtr) xmlNewNs(self, ns->href, ns->prefix);
        }
    }
    if (newChild->type == XML_ELEMENT_NODE && _domIsDoc(self)) {
        // special case of appending root nodes to a document
        xmlDocPtr doc = (xmlDocPtr)self;
        if (xmlDocGetRootElement(doc) == NULL) {
            xmlDocSetRootElement(doc, newChild);
            return newChild;
        }
        else {
            XML6_FAIL(self, "appendChild: Unable to append additional root elements");
        }
    }

    if ( !(domTestHierarchy(self, newChild)
           && domTestDocument(self, newChild))){
        XML6_FAIL(self, "appendChild: HIERARCHY_REQUEST_ERR");
    }

    if ( newChild->doc == self->doc ){
        domUnlinkNode( newChild );
    }
    else {
        newChild = domImportNode( self->doc, newChild, 1, 0 );
    }

    if ( self->children != NULL ) {
        head = _domAddNodeToList( newChild, self->last, NULL, &tail );
    }
    else if (newChild->type == XML_DOCUMENT_FRAG_NODE) {
        xmlNodePtr c1 = NULL;
        head = _domExtractFrag(newChild);
        self->children = head;
        c1 = head;
        while ( c1 ){
            c1->parent = self;
            self->last = c1;
            tail = c1;
            c1 = c1->next;
        }
    }
    else {
        head = tail = newChild;
        self->children = newChild;
        self->last     = newChild;
        newChild->parent = self;
    }

    _domAssimulate(head, tail);
    return head;
}

DLLEXPORT xmlNodePtr
domAppendTextChild( xmlNodePtr self, unsigned char *name, unsigned char *value) {
    xmlChar* buffer;
    xmlNodePtr rv = NULL;
    /* unlike xmlSetProp, xmlNewDocProp does not encode entities in value */
    buffer = xmlEncodeEntitiesReentrant(self->doc, value);
    rv = xmlNewChild( self, NULL, name, buffer );
    if ( buffer ) {
        xmlFree(buffer);
    }
    return rv;
}

DLLEXPORT xmlNodePtr
domRemoveChild( xmlNodePtr self, xmlNodePtr old ) {
    if ( self == NULL || old == NULL ) {
        return NULL;
    }
    if ( self != old->parent ) {
        int is_parent = 0; // not looking good...
        if (_domIsDoc(self) && old->type == XML_DTD_NODE) {
            // ...but there is the special case of doc/dtd relationship
            xmlDocPtr doc = (xmlDocPtr) self;
            xmlDtdPtr dtd = (xmlDtdPtr) old;
            is_parent |= domGetInternalSubset(doc) == dtd;
            is_parent |= domGetExternalSubset(doc) == dtd;
        }
        if (is_parent == 0) {
            /* old is not a child */
            return NULL;
        }
    }

    domUnlinkNode( old );
    if ( old->type == XML_ELEMENT_NODE ) {
        domReconcileNs( old );
    }

    return old ;
}

DLLEXPORT xmlNodePtr
domReplaceChild( xmlNodePtr self, xmlNodePtr new, xmlNodePtr old ) {
    xmlNodePtr head = new;
    xmlNodePtr tail = new;

    if ( self == NULL )
        return NULL;

    if ( new == old )
        return NULL;

    if ( new == NULL ) {
        /* level2 says nothing about this case :( */
        return domRemoveChild( self, old );
    }

    if (new->type == XML_DTD_NODE) {
        _domSetDtd((xmlDocPtr)self, (xmlDtdPtr)new, old);
    }
    else if ( old == NULL ) {
        domAppendChild( self, new );
    }
    else {
        if ( !(domTestHierarchy(self, new)
               && domTestDocument(self, new))){
            XML6_FAIL(self, "replaceChild: HIERARCHY_REQUEST_ERR");
        }

        if ( new->doc == self->doc ) {
            domUnlinkNode( new );
        }
        else {
            new = domImportNode( self->doc, new, 1, 1 );
        }

        if( old == self->children && old == self->last ) {
            domRemoveChild( self, old );
            domAppendChild( self, new );
        }
        else {
            head = _domAddNodeToList(new, old->prev, old->next, &tail );
            old->parent = old->next = old->prev = NULL;
            if ( head ) {
                _domAssimulate(head, tail);
            }

        }
    }

    return old;
}

DLLEXPORT xmlNodePtr
domInsertBefore( xmlNodePtr self,
                 xmlNodePtr newChild,
                 xmlNodePtr refChild ){
    xmlNodePtr head = newChild;
    xmlNodePtr tail = newChild;
    if ( refChild == newChild ) {
        return newChild;
    }

    if ( self == NULL || newChild == NULL ) {
        return NULL;
    }

    if ( refChild != NULL ) {
        if ( refChild->parent != self ) {
            XML6_FAIL(self, "insertBefore/insertAfter: NOT_FOUND_ERR");
        }
    }

    if ( self->children == NULL ) {
        return domAppendChild( self, newChild );
    }

    if (newChild->type == XML_DTD_NODE) {
        return _domSetDtd((xmlDocPtr)self, (xmlDtdPtr)newChild, NULL);
    }

    if ( !(domTestHierarchy( self, newChild )
           && domTestDocument( self, newChild ))) {
        XML6_FAIL(self, "insertBefore/insertAfter: HIERARCHY_REQUEST_ERR");
    }

    if ( self->doc == newChild->doc ){
        domUnlinkNode( newChild );
    }
    else {
        newChild = domImportNode( self->doc, newChild, 1, 0 );
    }

    if ( refChild == NULL ) {
        head = _domAddNodeToList(newChild, self->last, NULL, &tail);
    }
    else {
        head = _domAddNodeToList(newChild, refChild->prev, refChild, &tail);
    }

    return _domAssimulate(head, tail);
}

/*
 * this function does not exist in the spec although it's useful
 */
DLLEXPORT xmlNodePtr
domInsertAfter( xmlNodePtr self,
                xmlNodePtr newChild,
                xmlNodePtr refChild ){
    if ( refChild == NULL ) {
        return domInsertBefore( self, newChild, NULL );
    }
    return domInsertBefore( self, newChild, refChild->next );
}

DLLEXPORT xmlNodePtr
domReplaceNode( xmlNodePtr self, xmlNodePtr newNode ) {
    xmlNodePtr prev = NULL, next = NULL, par = NULL;
    xmlNodePtr head = newNode;
    xmlNodePtr tail = newNode;

    if ( self == NULL
         || newNode == NULL ) {
        return NULL;
    }

    if ( self->type == XML_ATTRIBUTE_NODE
         || newNode->type == XML_ATTRIBUTE_NODE
         || _domIsDoc(self)
         || _domIsDoc(newNode)
         || domIsParent( newNode, self ) ) {
        /* HIERARCHY_REQUEST_ERR
         * wrong node type
         * new node is parent of itself
         */
        XML6_FAIL(self, "replaceNode: HIERARCHY_REQUEST_ERR");
    }

    if ( newNode->type == XML_DTD_NODE) {
        _domSetDtd((xmlDocPtr)self->parent, (xmlDtdPtr)newNode, self);
    }
    else {
        par  = self->parent;
        prev = self->prev;
        next = self->next;

        domUnlinkNode( self );

        if (prev == NULL && next == NULL ) {
            /* self was the only child */
            domAppendChild( par , newNode );
        }
        else {
            if ( newNode->doc == self->doc ){
                domUnlinkNode( newNode );
            }
            else {
                newNode = domImportNode( self->doc, newNode, 1, 0 );
            }

            head = _domAddNodeToList( newNode, prev,  next, &tail );
            _domAssimulate(head, tail);
        }
    }
    return self;
}

DLLEXPORT xmlNodePtr
domRemoveChildNodes( xmlNodePtr self) {
    xmlNodePtr frag = xmlNewDocFragment( self->doc );
    xmlNodePtr cur = self->children;
    while ( cur ) {
	// remove dtd and attributes without transferring
        xmlNodePtr next = cur->next;
        if (cur->type == XML_ATTRIBUTE_NODE
            || cur->type == XML_DTD_NODE) {
            domReleaseNode( cur );
        }
	cur = next;
    }
    // transfer other kids
    frag->children = self->children;
    frag->last = self->last;
    self->children = self->last = NULL;
    cur = frag->children;

    // reparent
    while ( cur ) {
        cur->parent = frag;
        cur = cur->next;
    }
    return frag;
}

DLLEXPORT xmlNodePtr
domAddSibling( xmlNodePtr self, xmlNodePtr nNode ) {

    xmlNodePtr rv = NULL;

    if (self == NULL) {
        return nNode;
    }

    if ( nNode && nNode->type == XML_DOCUMENT_FRAG_NODE ) {
        XML6_FAIL(self, "Adding document fragments with addSibling not yet supported!");
    }

    if (self->type == XML_TEXT_NODE && nNode->type == XML_TEXT_NODE
        && self->name == nNode->name) {
        /* As a result of text merging, the added node may be freed. */
        xmlNodePtr copy = xmlCopyNode(nNode, 0);
        rv = xmlAddSibling(self, copy);

        if (rv) {
	    domReleaseNode(nNode);
        }
        else {
            domReleaseNode(copy);
        }
    }
    else if (nNode->type == XML_DTD_NODE) {
        rv = _domSetDtd((xmlDocPtr)self->parent, (xmlDtdPtr)nNode, NULL);
    }
    else {
        rv = xmlAddSibling( self, nNode );
    }
    return rv;
}

DLLEXPORT xmlChar*
domGetNodeValue( xmlNodePtr n ) {
    xmlChar*  rv = NULL;
    if( n != NULL ) {
        switch ( n->type ) {
        case XML_ATTRIBUTE_NODE:
        case XML_ENTITY_DECL:
        case XML_TEXT_NODE:
        case XML_COMMENT_NODE:
        case XML_CDATA_SECTION_NODE:
        case XML_PI_NODE:
        case XML_ENTITY_REF_NODE:
            break;
        default:
            return rv;
            break;
        }
        if ( n->type != XML_ENTITY_DECL ) {
            rv = xmlXPathCastNodeToString(n);
        }
        else {
            if ( n->content != NULL ) {
                rv = xmlStrdup(n->content);
            }
            else if ( n->children != NULL ) {
                xmlNodePtr cnode = n->children;
                /* ok then toString in this case ... */
                while (cnode) {
                    xmlBufferPtr buffer = xmlBufferCreate();
                    /* buffer = xmlBufferCreate(); */
                    xmlNodeDump( buffer, n->doc, cnode, 0, 0 );
                    if ( buffer->content != NULL ) {
                        if ( rv != NULL ) {
                            rv = xmlStrcat( rv, buffer->content );
                        }
                        else {
                            rv = xmlStrdup( buffer->content );
                        }
                    }
                    xmlBufferFree( buffer );
                    cnode = cnode->next;
                }
            }
        }
    }

    return rv;
}

DLLEXPORT void
domSetNodeValue( xmlNodePtr n , xmlChar* val ){
    if ( n == NULL )
        return;
    if ( val == NULL ){
        val = (xmlChar*) "";
    }

    if( n->type == XML_ATTRIBUTE_NODE ){
        /* can't use xmlNodeSetContent - for Attrs it parses entities */
        if ( n->children != NULL ) {
            // clear existing attribute content
            xmlNodePtr content = n->children;
            while (content) {
                xmlNodePtr next = content->next;
                domReleaseNode(content);
                content = next;
            }
        }
        n->children = xmlNewText( val );
        n->children->parent = n;
        n->children->doc = n->doc;
        n->last = n->children;
    }
    else {
        xmlNodeSetContent( n, val );
    }
}

DLLEXPORT xmlElementType
domNodeType(xmlChar* name) {
    xmlElementType node_type = 0;

    if (name != NULL) {
        switch (name[0]) {
            case '?' :
                node_type = XML_PI_NODE;
                break;
            case '&' :
                node_type = XML_ENTITY_REF_NODE;
                break;
            case '#': {
                switch (name[1]) {
                    case 'c':
                        if (xmlStrcmp( name, (xmlChar*) "#comment" ) == 0) {
                            node_type = XML_COMMENT_NODE;
                        }
                        else if (xmlStrcmp( name, (xmlChar*) "#cdata" ) == 0
                                 || xmlStrcmp( name, (xmlChar*) "#cdata-section" ) == 0) {
                            node_type = XML_CDATA_SECTION_NODE;
                        }
                        break;

                    case 'd':
                        if (xmlStrcmp( name, (xmlChar*) "#document" ) == 0) {
                            node_type = XML_DOCUMENT_NODE;
                        }
                        else if (xmlStrcmp( name, (xmlChar*) "#document-fragment" ) == 0) {
                            node_type = XML_DOCUMENT_FRAG_NODE;
                        }
#ifdef LIBXML_DOCB_ENABLED
                        else if (xmlStrcmp( name, (xmlChar*) "#docbook" ) == 0) {
                            node_type = XML_DOCB_DOCUMENT_NODE;
                        }
#endif
                        break;

                    case 'h':
                        if (xmlStrcmp( name, (xmlChar*) "#html" ) == 0) {
                            node_type = XML_HTML_DOCUMENT_NODE;
                        }
                        break;

                    case 'f':
                        if (xmlStrcmp( name, (xmlChar*) "#fragment" ) == 0) {
                            node_type = XML_DOCUMENT_FRAG_NODE;
                        }
                        break;

                    case 't':
                        if (xmlStrcmp( name, (xmlChar*) "#text" ) == 0) {
                            node_type = XML_TEXT_NODE;
                        }
                        break;

                    case 'x':
                        if (xmlStrcmp( name, (xmlChar*) "#xml" ) == 0) {
                            node_type = XML_DOCUMENT_NODE;
                        }
                        break;
                }
                if (node_type == 0) {
                    fprintf(stderr, __FILE__ "%d: unknown node generic name '%s'\n", __LINE__, name);
                }
                break;
            }
            default: {
                node_type = XML_ELEMENT_NODE;
                break;
            }
        }
    }

    return node_type;
}

DLLEXPORT xmlNodeSetPtr
domGetChildrenByLocalName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = self->children;
    xmlElementType node_type = 0;

    if ( self != NULL && name != NULL ) {

        switch (*name) {
            case '*' : {     // -- Element wildcard
                name = NULL;
                node_type = XML_ELEMENT_NODE;
                break;
            }
            case '?' : {     // -- Named PI node
                name++; // skip leading '?'
                if (*name == '*') name = NULL; // "?*" wildcard
                node_type = XML_PI_NODE;
                break;
            }
            case '@' : {     // -- Named Attribute
                name++; // skip leading '@'
                if (*name == '*') name = NULL; // "@*" wildcard
                node_type = XML_ATTRIBUTE_NODE;
                cld = (xmlNodePtr) self->properties; // scan attributes instead of children
                break;
            }
            default : {      // anything else
                node_type = domNodeType(name);
                if (*name == '#') name = NULL; // generic name
                break;
            }
        }

        while ( cld != NULL ) {
            if ( cld->type == node_type
              && (name == NULL || xmlStrcmp( name, cld->name ) == 0 )) {
                if ( rv == NULL ) {
                    rv = xmlXPathNodeSetCreate( cld ) ;
                }
                else {
                    domPushNodeSet( rv, cld, 0 );
                }
            }
            cld = cld->next;
        }
    }

    return rv;
}

static int _domNamecmp(xmlNodePtr self, const xmlChar* pname) {
    const xmlChar* name = domGetNodeName(self);
    return xmlStrcmp( name, pname );
}

static xmlNodeSetPtr
_domMergeNodeSet(xmlNodeSetPtr self, xmlNodeSetPtr nodes) {
    xmlNodeSetPtr rv = NULL;

    if (nodes == NULL) {
        rv = self;
    }
    else if (self == NULL) {
        rv = nodes;
    }
    else {
        int i;
        rv = self;
        for (i = 0; i < nodes->nodeNr; i++) {
            domPushNodeSet(self, nodes->nodeTab[i], 0);
        }
        xmlXPathFreeNodeSet(nodes);
    }

    return rv;
}


DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = NULL;
    unsigned int any_elem;

    if ( self != NULL && name != NULL ) {
        any_elem = (xmlStrcmp( name, (unsigned char *) "*" ) == 0);
        cld = self->children;

        while ( cld != NULL ) {
            if ( ((any_elem && cld->type == XML_ELEMENT_NODE)
                  || _domNamecmp( cld, name ) == 0 )) {
                if ( rv == NULL ) {
                    rv = xmlXPathNodeSetCreate( cld ) ;
                }
                else {
                    domPushNodeSet( rv, cld, 0 );
                }
            }
            cld = cld->next;
        }
    }

    return rv;
}

DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagNameNS( xmlNodePtr self, xmlChar* nsURI, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    int any_name;
    xmlNodePtr cld;

    if ( self != NULL && name != NULL && nsURI != NULL ) {
        if ( xmlStrcmp( nsURI, (unsigned char *) "*" ) == 0) {
            rv = domGetChildrenByLocalName(self, name);
        }
        else {
            any_name = xmlStrcmp( name, (unsigned char *) "*" ) == 0;
            cld = self->children;
            while ( cld != NULL ) {
                if (((any_name &&  cld->type == XML_ELEMENT_NODE)
                     || xmlStrcmp( name, cld->name ) == 0)
                    && cld->ns != NULL
                    && xmlStrcmp( nsURI, cld->ns->href ) == 0  ){
                    if ( rv == NULL ) {
                        rv = xmlXPathNodeSetCreate( cld ) ;
                    }
                    else {
                        domPushNodeSet( rv, cld, 0 );
                    }
                }
                cld = cld->next;
            }
        }
    }

    return rv;
}

DLLEXPORT xmlNodeSetPtr
domGetElementsByLocalName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = NULL;
    int any_name;
    xmlNodeSetPtr elems;

    if ( self != NULL && name != NULL ) {
        any_name =  xmlStrcmp( name, (unsigned char *) "*" ) == 0;
        cld = self->children;
        while ( cld != NULL ) {
            if ( cld->type == XML_ELEMENT_NODE ) {
                if (any_name || xmlStrcmp( cld->name, name ) == 0 ) {
                    if ( rv == NULL ) {
                        rv = xmlXPathNodeSetCreate( cld ) ;
                    }
                    else {
                        domPushNodeSet( rv, cld, 0 );
                    }
                }
                elems = domGetElementsByLocalName(cld, name);
                rv = _domMergeNodeSet(rv, elems);
            }
            cld = cld->next;
        }
    }

    return rv;
}

DLLEXPORT xmlNodeSetPtr
domGetElementsByTagName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = NULL;
    int any_name;
    xmlNodeSetPtr elems;

    if ( self != NULL && name != NULL ) {
        any_name =  xmlStrcmp( name, (unsigned char *) "*" ) == 0;
        cld = self->children;
        while ( cld != NULL ) {
            if ( cld->type == XML_ELEMENT_NODE) {
                if (any_name || _domNamecmp( cld, name ) == 0 ) {
                    if ( rv == NULL ) {
                        rv = xmlXPathNodeSetCreate( cld ) ;
                    }
                    else {
                        domPushNodeSet( rv, cld, 0 );
                    }
                }
                elems = domGetElementsByTagName(cld, name);
                rv = _domMergeNodeSet(rv, elems);
            }
            cld = cld->next;
        }
    }

    return rv;
}

DLLEXPORT xmlNodeSetPtr
domGetElementsByTagNameNS( xmlNodePtr self, xmlChar* nsURI, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    int any_name;
    xmlNodePtr cld;
    xmlNodeSetPtr elems;

    if ( self != NULL && name != NULL && nsURI != NULL ) {
        if ( xmlStrcmp( nsURI, (unsigned char *) "*" ) == 0) {
            rv = domGetElementsByLocalName(self, name);
        }
        else {
            any_name = xmlStrcmp( name, (unsigned char *) "*" ) == 0;
            cld = self->children;
            while ( cld != NULL ) {
                if (cld->type == XML_ELEMENT_NODE) {
                    if ((any_name || xmlStrcmp( name, cld->name ) == 0)
                        && cld->ns != NULL
                        && xmlStrcmp( nsURI, cld->ns->href ) == 0  ){
                        if ( rv == NULL ) {
                            rv = xmlXPathNodeSetCreate( cld ) ;
                        }
                        else {
                            domPushNodeSet( rv, cld, 0 );
                        }
                    }
                    elems = domGetElementsByTagNameNS(cld, nsURI, name);
                    rv = _domMergeNodeSet(rv, elems);
                }
                cld = cld->next;
            }
        }
    }

    return rv;
}

DLLEXPORT xmlAttrPtr
domGetAttributeNode(xmlNodePtr node, const xmlChar* qname) {
    xmlChar*  prefix    = NULL;
    xmlChar*  localname = NULL;
    xmlAttrPtr rv = NULL;
    xmlNsPtr ns = NULL;

    if ( qname == NULL || node == NULL )
        return NULL;

    /* first try qname without namespace */
    rv = xmlHasNsProp(node, qname, NULL);
    if ( rv == NULL ) {
        localname = xmlSplitQName2(qname, &prefix);
        if ( localname != NULL ) {
            ns = xmlSearchNs( node->doc, node, prefix );
            if ( ns != NULL ) {
                /* then try localname with the namespace bound to prefix */
                rv = xmlHasNsProp( node, localname, ns->href );
            }
            if ( prefix != NULL) {
                xmlFree( prefix );
            }
            xmlFree( localname );
        }
    }
    if (rv && rv->type != XML_ATTRIBUTE_NODE) {
        rv = NULL;  /* we don't want fixed attribute decls */
    }
    return rv;
}

DLLEXPORT int
domHasAttributeNS(xmlNodePtr self, const xmlChar* nsURI, const xmlChar* name) {
    int rv = 0;
    xmlAttrPtr attr = NULL;

    if ( name && *name ) {
        if (nsURI && !*nsURI) {
            nsURI = NULL;
        }

        attr = xmlHasNsProp( self, name, nsURI );

        if (attr) {
            /* we don't want fixed attribute decls */
            rv = attr->type == XML_ATTRIBUTE_NODE;
        }
    }

    return rv;
}

DLLEXPORT int
domSetNamespaceDeclURI( xmlNodePtr self, xmlChar* prefix, xmlChar* nsURI ) {
    xmlNsPtr ns = self->nsDef;
    int rv = 0;

    /* null empty values */
    if ( prefix && !*prefix) {
        prefix = NULL;
    }
    if ( nsURI && !*nsURI) {
        nsURI = NULL;
    }

    while ( ns ) {
        if ((ns->prefix || ns->href ) &&
            ( xmlStrcmp( ns->prefix, prefix ) == 0 )) {
            if (ns->href) xmlFree((char*)ns->href);
            ns->href = xmlStrdup(nsURI);
            if ( nsURI == NULL ) {
                domRemoveNsRefs( self, ns );
            } else {
                nsURI = NULL; /* do not free it */
            }
            rv = 1;
            break;
        } else {
            ns = ns->next;
        }
    }
    return rv;
}

DLLEXPORT const xmlChar*
domGetNamespaceDeclURI(xmlNodePtr self, const xmlChar* prefix ) {
    const xmlChar* rv = NULL;
    xmlNsPtr ns = self->nsDef;

    if ( prefix != NULL && !*prefix) {
        prefix = NULL;
    }

    while ( ns != NULL ) {
        if ( (ns->prefix != NULL || ns->href != NULL) &&
             xmlStrcmp( ns->prefix, prefix ) == 0 ) {
            rv = ns->href;
            break;
        } else {
            ns = ns->next;
        }
    }
    return xml6_gbl_cache_dup(rv);
}

DLLEXPORT int
domSetNamespaceDeclPrefix(xmlNodePtr self, xmlChar* prefix, xmlChar* new_prefix ) {
    xmlNsPtr ns;
    int rv = 0;

    if (prefix && !*prefix) prefix = NULL;
    if (new_prefix && !*new_prefix) new_prefix = NULL;

    if ( xmlStrcmp( prefix, new_prefix ) == 0 ) {
        rv = 1;
    } else {
        /* check that new prefix is not in scope */
        ns = xmlSearchNs( self->doc, self, new_prefix );
        if ( ns != NULL ) {
            char msg[80];
            snprintf(msg, sizeof(msg), "setNamespaceNsDeclPrefix: prefix '%s' is in use", ns->prefix);
            XML6_FAIL_i(self, msg);
        }
        /* lookup the declaration */
        ns = self->nsDef;
        while ( ns != NULL ) {
            if ((ns->prefix != NULL || ns->href != NULL) &&
                xmlStrcmp( ns->prefix, prefix ) == 0 ) {
                if ( ns->href == NULL && new_prefix != NULL ) {
                    /* xmlns:foo="" - no go */
                    XML6_FAIL_i(self, "setNamespaceDeclPrefix: cannot set non-empty prefix for empty namespace");
                }
                if ( ns->prefix != NULL )
                    xmlFree( (xmlChar*)ns->prefix );
                ns->prefix = xmlStrdup(new_prefix);
                new_prefix = NULL; /* do not free it */
                rv = 1;
                break;
            } else {
                ns = ns->next;
            }
        }
    }
    return rv;
}

DLLEXPORT const xmlChar*
domGetAttributeNS(xmlNodePtr self, const xmlChar* nsURI, const xmlChar* name) {
    xmlChar* rv = NULL;

    if ( nsURI && *nsURI) {
        if ( xmlStrcmp(nsURI, XML_XMLNS_NS) == 0) {
            if (name && xmlStrcmp(name, (xmlChar*)"xmlns") == 0)
                name = NULL;
            rv = xmlStrdup(domGetNamespaceDeclURI(self, name));
        }
        else {
            rv = xmlGetNsProp( self, name, nsURI );
        }
    }
    else {
        rv = xmlGetProp( self, name );
    }
    return rv;
}

DLLEXPORT xmlAttrPtr
domGetAttributeNodeNS(xmlNodePtr self, const xmlChar* nsURI, const xmlChar* name) {
    xmlAttrPtr rv = NULL;
    if (nsURI && !*nsURI)
        nsURI = NULL;

    if ( nsURI ) {
        rv = xmlHasNsProp( self, name, nsURI );
    }
    else {
        rv = xmlHasNsProp( self, name, NULL );
    }
    if (rv && rv->type != XML_ATTRIBUTE_NODE) {
        /* we don't want fixed attribute decls */
        rv = NULL;
    }
    return rv;
}

DLLEXPORT xmlChar*
domGetAttribute(xmlNodePtr node, const xmlChar* qname) {
    xmlChar*  prefix    = NULL;
    xmlChar*  localname = NULL;
    xmlChar*  rv = NULL;
    xmlNsPtr ns = NULL;

    if ( qname == NULL || node == NULL )
        return NULL;

    /* first try qname without namespace */
    rv = xmlGetNoNsProp(node, qname);

    if ( rv == NULL ) {
        localname = xmlSplitQName2(qname, &prefix);
        if ( localname != NULL ) {
            ns = xmlSearchNs( node->doc, node, prefix );
            if ( ns != NULL ) {
                /* then try localname with the namespace bound to prefix */
                rv = xmlGetNsProp( node, localname, ns->href );
            }
            if ( prefix != NULL) {
                xmlFree( prefix );
            }
            xmlFree( localname );
        }
    }

    return rv;
}

static void _addAttr(xmlNodePtr node, xmlAttrPtr attr) {
    /* stolen from libxml2 */
    if ( attr != NULL ) {
        if (node->properties == NULL) {
            node->properties = attr;
        } else {
            xmlAttrPtr prev = node->properties;

            while (prev->next != NULL) prev = prev->next;
            prev->next = attr;
            attr->prev = prev;
        }
        attr->parent = node;
    }
}

DLLEXPORT int
domSetAttribute( xmlNodePtr self, xmlChar* name, xmlChar* value ) {
    xmlAttrPtr node = NULL;
    node = xmlSetProp(self, name, value);
    return(node != NULL);
}

DLLEXPORT xmlAttrPtr
domSetAttributeNode( xmlNodePtr self, xmlAttrPtr attr ) {
    xmlAttrPtr old = NULL;

    if ( self == NULL || attr == NULL ) {
        return attr;
    }
    if ( attr->type != XML_ATTRIBUTE_NODE )
        return NULL;
    if ( self == attr->parent ) {
        return attr; /* attribute is already part of the node */
    }
    if ( attr->doc != self->doc ){
        domImportNode( self->doc, (xmlNodePtr) attr, 1, 1 );
    }

    old = domGetAttributeNode(self, attr->name);

    if ( old && old->type == XML_ATTRIBUTE_NODE ) {
        if ( old == attr) {
            return attr;
        }
        domReleaseNode( (xmlNodePtr)old );
    }
    xmlUnlinkNode( (xmlNodePtr) attr );
    _addAttr( self, attr);

    return attr;
}

DLLEXPORT xmlAttrPtr
domSetAttributeNodeNS( xmlNodePtr self, xmlAttrPtr attr ) {
    xmlAttrPtr old = NULL;
    const xmlChar* href = NULL;
    if ( self == NULL || attr == NULL ) {
        return attr;
    }

    if ( attr->type != XML_ATTRIBUTE_NODE )
        return NULL;
    if ( self == attr->parent ) {
        return attr; /* attribute is already part of the node */
    }
    if ( attr->doc != self->doc ){
        domImportNode( self->doc, (xmlNodePtr) attr, 1, 1 );
    }
    
    href = attr->ns ? attr->ns->href : NULL;
    old = xmlHasNsProp( self, attr->name, href );

    if ( old && old->type == XML_ATTRIBUTE_NODE ) {
        if ( old == attr) {
            return attr;
        }
        domReleaseNode( (xmlNodePtr)old );
    }

    xmlUnlinkNode( (xmlNodePtr) attr );
    _addAttr( self, attr);

    return attr;
}

DLLEXPORT xmlChar*
domAttrSerializeContent(xmlAttrPtr attr) {
    xmlBufferPtr buffer = xmlBufferCreate();
    xmlNodePtr children;
    xmlChar* rv = NULL;

    if (attr == NULL) return(NULL);

    children = attr->children;
    while (children != NULL) {
        switch (children->type) {
        case XML_TEXT_NODE:
            xmlAttrSerializeTxtContent(buffer, attr->doc,
                                       attr, children->content);
            break;
        case XML_ENTITY_REF_NODE:
            xmlBufferAdd(buffer, BAD_CAST "&", 1);
            xmlBufferAdd(buffer, children->name,
                         xmlStrlen(children->name));
            xmlBufferAdd(buffer, BAD_CAST ";", 1);
            break;
        default:
            /* should not happen unless we have a badly built tree */
            break;
        }
        children = children->next;
    }

    rv = buffer->content;
    buffer->content = NULL;
    xmlBufferFree( buffer );

    return rv;
}

// check if prefix is of the form: base<digit+>
static int _domPrefixMatch(const xmlChar *prefix, xmlChar *base) {
    int len = xmlStrlen(base);
    int matched = 0;
    if (prefix && xmlStrncmp(prefix, base, len) == 0) {
        while (prefix[len]) {
            char d = prefix[len];
            if (d >= '0' && d <= '9' && matched <= 5) {
                matched++;
            }
            else {
                // encountered non-digit, or too large; abort match
                matched = 0;
                break;
            }
            len++;
        }
    }
    return matched;
}

DLLEXPORT const xmlChar*
domGenNsPrefix(xmlNodePtr self, xmlChar* base) {
    xmlChar* rv;
    xmlNsPtr *all_ns = xmlGetNsList(self->doc, self);
    xmlHashTablePtr hash = xmlHashCreate(10);
    char entry[1];

    if (base == NULL || *base == 0) {
        base = (xmlChar*) "_ns";
    }

    if ( all_ns ) {
        int i = 0;
        xmlNsPtr ns = all_ns[i];
        while ( ns ) {
            if (_domPrefixMatch(ns->prefix, base)) {
                // found an entry of the form base<n>
                const xmlChar *key = ns->prefix;
                if (xmlHashLookup(hash, (xmlChar*)key) == NULL) {
                    xmlHashAddEntry(hash, xmlStrdup((xmlChar*)key), entry);
                }
            }
            ns = all_ns[i++];
        }
        xmlFree(all_ns);
    }

    {
        int seq;
        int spare = 0;
        rv = xmlMalloc(xmlStrlen(base) + 6);
        // iterate until we generate an unused suffix
        for (seq = 0; !spare; seq++) {
            sprintf((char*)rv, "%s%d", base, seq);
            spare = xmlHashLookup(hash, (xmlChar*)rv) == NULL;
        }
    }

    xmlHashFree(hash, NULL);
    return xml6_gbl_cache(rv);
}

DLLEXPORT int
domNormalizeList( xmlNodePtr nodelist ) {
    while ( nodelist ){
        if ( domNormalize( nodelist ) == 0 )
            return(0);
        nodelist = nodelist->next;
    }
    return(1);
}

DLLEXPORT int
domNormalize( xmlNodePtr node ) {
    xmlNodePtr next = NULL;

    if ( node == NULL )
        return(0);

    switch ( node->type ) {
    case XML_TEXT_NODE:
        while ( node->next
                && node->next->type == XML_TEXT_NODE ) {
            next = node->next;
            xmlNodeAddContent(node, next->content);
            domReleaseNode( next );
        }
        break;
    case XML_ELEMENT_NODE:
        domNormalizeList( (xmlNodePtr) node->properties );
        /* FALLTHRU */
    case XML_ATTRIBUTE_NODE:
    case XML_DOCUMENT_NODE:
        return( domNormalizeList( node->children ) );
        break;
    default:
        break;
    }
    return(1);
}

DLLEXPORT int
domRemoveNsRefs(xmlNodePtr tree, xmlNsPtr ns) {
    xmlAttrPtr attr;
    xmlNodePtr node = tree;

    if ((node == NULL) || (node->type != XML_ELEMENT_NODE)) return(0);
    while (node != NULL) {
        if (node->ns == ns)
            node->ns = NULL; /* remove namespace reference */
        attr = node->properties;
        while (attr != NULL) {
            if (attr->ns == ns)
                attr->ns = NULL; /* remove namespace reference */
            attr = attr->next;
        }
        /*
         * Browse the full subtree, deep first
         */
        if (node->children != NULL && node->type != XML_ENTITY_REF_NODE) {
            /* deep first */
            node = node->children;
        } else if ((node != tree) && (node->next != NULL)) {
            /* then siblings */
            node = node->next;
        } else if (node != tree) {
            /* go up to parents->next if needed */
            while (node != tree) {
                if (node->parent != NULL)
                    node = node->parent;
                if ((node != tree) && (node->next != NULL)) {
                    node = node->next;
                    break;
                }
                if (node->parent == NULL) {
                    node = NULL;
                    break;
                }
            }
            /* exit condition */
            if (node == tree)
                node = NULL;
        } else
            break;
    }
    return(1);
}

DLLEXPORT xmlAttrPtr
domCreateAttribute( xmlDocPtr self, unsigned char *name, unsigned char *value) {
    xmlChar* buffer;
    xmlAttrPtr newAttr;
    /* unlike xmlSetProp, xmlNewDocProp does not encode entities in value */
    buffer = xmlEncodeEntitiesReentrant(self, value);
    newAttr = xmlNewDocProp( self, name, buffer );
    xmlFree(buffer);
    return newAttr;
}

DLLEXPORT xmlAttrPtr
domCreateAttributeNS( xmlDocPtr self, unsigned char *URI, unsigned char *name, unsigned char *value ) {
    xmlChar*  prefix = NULL;
    xmlChar*  localname = NULL;
    xmlAttrPtr newAttr = NULL;
    xmlNsPtr ns = NULL;
    xmlNodePtr root = xmlDocGetRootElement(self);

    if ( URI != NULL && *URI) {
        if ( xmlStrchr(name, ':') != NULL ) {
            localname = xmlSplitQName2(name, &prefix);
        }
        else {
            localname = xmlStrdup( name );
        }

        if ( root != NULL ) {
            ns = xmlSearchNsByHref( self, root, URI );
        }
        if ( ns == NULL ) {
            /* create a new NS if the NS does not already exists */
            ns = xmlNewNs(root, URI , prefix );
        }

        if ( ns == NULL ) {
            XML6_FAIL(self, "unable to create Attribute namespace");
        }

        newAttr = xmlNewDocProp( self, localname, value );
        xmlSetNs((xmlNodePtr)newAttr, ns);

        if ( prefix ) {
            xmlFree(prefix);
        }
        xmlFree(localname);
    }
    else {
        newAttr = domCreateAttribute(self, name, value);
    }

    return newAttr;
}

static xmlNsPtr _domNsSearch(xmlNodePtr self, xmlChar* nsURI) {
    xmlNsPtr ns = xmlSearchNsByHref( self->doc, self, nsURI );

    if ( ns && !ns->prefix ) {
        /*
         * check for any prefixed namespaces occluded by a default namespace
         * because xmlSearchNsByHref will return default namespaces unless
         * you are searching on an attribute node, which may not exist yet
         */
        xmlNsPtr *all_ns = xmlGetNsList(self->doc, self);

        if ( all_ns ) {
            int i = 0;
            ns = all_ns[i];
            while ( ns ) {
                if ( ns->prefix && xmlStrEqual(ns->href, nsURI) ) {
                    break;
                }
                ns = all_ns[i++];
            }
            xmlFree(all_ns);
        }
    }

    return ns;
}

DLLEXPORT xmlAttrPtr
domSetAttributeNS(xmlNodePtr self, xmlChar* nsURI, xmlChar* name, xmlChar* value ) {
    xmlNsPtr   ns        = NULL;
    xmlChar*   localname = NULL;
    xmlChar*   prefix    = NULL;
    xmlAttrPtr newAttr   = NULL;

    if (self && name && value) {

        localname = xmlSplitQName2(name, &prefix);
        if ( localname ) {
            /* try without namespace */
            xmlAttrPtr oldAttr = xmlHasNsProp(self, name, NULL);
            if (oldAttr != NULL) {
                domReleaseNode((xmlNodePtr) oldAttr);
            }
            name = localname;
        }

        if (nsURI && *nsURI) {
            ns = _domNsSearch(self, nsURI);
            if ( ns == NULL ) {
                ns = xmlNewNs(self, nsURI , prefix );

                if (prefix != NULL && *prefix != 0 ) {
                    /* NS does not already exist, but we have a prefix; create a local NS on the node */
                    if (ns == NULL) {
                        XML6_FAIL(self, "bad namespace");
                    }
                }
                else {
                    XML6_FAIL(self, "unable to generate namespace without a prefix");
                }
            }
        }

        newAttr = xmlSetNsProp( self, ns, name, value );

        if ( prefix ) {
            xmlFree( prefix );
        }

        if ( localname ) {
            xmlFree( localname );
        }

    }

    return newAttr;
}

DLLEXPORT int
domSetNamespace(xmlNodePtr node, xmlChar* nsURI, xmlChar* nsPrefix, int activate) {
    xmlNsPtr ns = NULL;
    int rv = 0;

    if (nsPrefix != NULL && !*nsPrefix) nsPrefix = NULL;
    if (nsURI    != NULL && !*nsURI) nsURI = NULL;
  
    if ( nsPrefix == NULL && nsURI == NULL ) {
        /* special case: empty namespace */
        if ( (ns = xmlSearchNs(node->doc, node, NULL)) &&
             ( ns->href && xmlStrlen( ns->href ) != 0 ) ) {
            /* won't take it */
            rv = 0;
        } else if ( activate ) {
            /* no namespace */
            xmlSetNs(node, NULL);
            rv = 1;
        } else {
            rv = 0;
        }
    }
    else if ( activate && (ns = xmlSearchNs(node->doc, node, nsPrefix)) ) {
        /* user just wants to set the namespace for the node */
        /* try to reuse an existing declaration for the prefix */
        if ( xmlStrEqual( ns->href, nsURI ) ) {
            rv = 1;
        }
        else if ( (ns = xmlNewNs( node, nsURI, nsPrefix )) ) {
            rv = 1;
        }
        else {
            rv = 0;
        }
    }
    else if ( (ns = xmlNewNs( node, nsURI, nsPrefix )) ) {
        rv = 1;
    }
    else {
        rv = 0;
    }

    if ( ns && activate ) {
        xmlSetNs(node, ns);
    }

    return rv;
}

DLLEXPORT xmlNodePtr
domAddNewChild( xmlNodePtr self, xmlChar* nsURI, xmlChar* name ) {
    xmlNodePtr newNode = NULL;
    xmlNodePtr prev = NULL;
    xmlNsPtr ns = NULL;

    if (self == NULL) return(NULL);
    if (nsURI && !*nsURI) nsURI = NULL;
    if (name && !*name) name = NULL;
  
    if ( nsURI != NULL ) {
        xmlChar* prefix     = NULL;
        xmlChar* localname = xmlSplitQName2(name, &prefix);
        ns = xmlSearchNsByHref(self->doc, self, nsURI);

        newNode = xmlNewDocNode(self->doc,
                                ns,
                                localname ? localname :name,
                                NULL);
        if ( ns == NULL )  {
            xmlSetNs(newNode,xmlNewNs(newNode, nsURI, prefix));
        }

        xmlFree(localname);
        xmlFree(prefix);
    }
    else {
        newNode = xmlNewDocNode(self->doc,
                                NULL,
                                name,
                                NULL);
    }
    /* add the node to the parent node */
    newNode->type = XML_ELEMENT_NODE;
    newNode->parent = self;
    newNode->doc = self->doc;

    if (self->children == NULL) {
        self->children = newNode;
        self->last = newNode;
    } else {
        prev = self->last;
        prev->next = newNode;
        newNode->prev = prev;
        self->last = newNode;
    }

    return newNode;
}

DLLEXPORT xmlChar* domFailure(xmlNodePtr self) {
    return xml6_ref_get_fail(self->_private);
}
DLLEXPORT xmlChar* domUniqueKey(void* self) {
    char key[20];
    sprintf(key, "%p", self);
    return xmlStrdup((xmlChar*)key);
}

DLLEXPORT int domIsSameNode(void* self, void* other) {
    return self == other;
}
