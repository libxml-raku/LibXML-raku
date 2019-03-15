/* $Id$
 *
 * This is free software, you may use it and distribute it under the same terms as
 * Perl itself.
 *
 * Copyright 2001-2003 AxKit.com Ltd., 2002-2006 Christian Glahn, 2006-2009 Petr Pajas
 * Ported from Perl 5 to 6 by David Warring
*/

#include "dom.h"
#include "xml6.h"
#include "xml6_node.h"

#define warn(string) {fprintf(stderr, "%s:%d: %s\n", __FILE__,__LINE__,(string));}
#define xs_warn(string) warn(string)
#define croak(string) {warn(string);return NULL;}

void
domClearPSVIInList(xmlNodePtr list);

void
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
    } else if (tree->type == XML_DOCUMENT_NODE) {
        ((xmlDocPtr) tree)->psvi = NULL;
    }
    if (tree->children != NULL)
        domClearPSVIInList(tree->children);
}

void
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

void
domAddNsDef(xmlNodePtr tree, xmlNsPtr ns)
{
        xmlNsPtr i = tree->nsDef;
        while(i != NULL && i != ns)
                i = i->next;
        if( i == NULL )
        {
                ns->next = tree->nsDef;
                tree->nsDef = ns;
        }
}

char
domRemoveNsDef(xmlNodePtr tree, xmlNsPtr ns)
{
        xmlNsPtr i = tree->nsDef;

        if( ns == tree->nsDef )
        {
                tree->nsDef = tree->nsDef->next;
                ns->next = NULL;
                return(1);
        }
        while( i != NULL )
        {
                if( i->next == ns )
                {
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
_domAddNsChain(xmlNsPtr c, xmlNsPtr ns)
{
        if( c == NULL )
                return(ns);
        else
        {
                xmlNsPtr i = c;
                while(i != NULL && i != ns)
                        i = i->next;
                if(i == NULL)
                {
                        ns->next = c;
                        return(ns);
                }
        }
        return(c);
}

/* We need to be smarter with attributes, because the declaration is on the parent element */
void
_domReconcileNsAttr(xmlAttrPtr attr, xmlNsPtr * unused)
{
        xmlNodePtr tree = attr->parent;
	if (tree == NULL)
		return;
        if( attr->ns != NULL )
        {
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
                    xmlStrcmp(ns->href,attr->ns->href) == 0 )
                {
                        /* Remove the declaration from the element */
                        if( domRemoveNsDef(tree, attr->ns) )
                                /* Queue up this namespace for freeing */
                                *unused = _domAddNsChain(*unused, attr->ns);

                        /* Replace the namespace with the one found */
                        attr->ns = ns;
                }
                else
                {
                        /* If the declaration is here, we don't need to do anything */
                        if( domRemoveNsDef(tree, attr->ns) )
                                domAddNsDef(tree, attr->ns);
                        else
                        {
                                /* Replace/Add the namespace declaration on the element */
                                attr->ns = xmlCopyNamespace(attr->ns);
				if (attr->ns) {
				  domAddNsDef(tree, attr->ns);
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

void
_domReconcileNs(xmlNodePtr tree, xmlNsPtr * unused)
{
        if( tree->ns != NULL
            && ((tree->type == XML_ELEMENT_NODE)
                || (tree->type == XML_ATTRIBUTE_NODE)))
        {
                xmlNsPtr ns = xmlSearchNs( tree->doc, tree->parent, tree->ns->prefix );
                if( ns != NULL && ns->href != NULL && tree->ns->href != NULL &&
                    xmlStrcmp(ns->href,tree->ns->href) == 0 )
                {
                        /* Remove the declaration (if present) */
                        if( domRemoveNsDef(tree, tree->ns) )
                                /* Queue the namespace for freeing */
                                *unused = _domAddNsChain(*unused, tree->ns);

                        /* Replace the namespace with the one found */
                        tree->ns = ns;
                }
                else
                {
                        /* If the declaration is here, we don't need to do anything */
                        if( domRemoveNsDef(tree, tree->ns) ) {
                              domAddNsDef(tree, tree->ns);
                        }
                        else
                        {
                                /* Restart the namespace at this point */
                                tree->ns = xmlCopyNamespace(tree->ns);
                                domAddNsDef(tree, tree->ns);
                        }
                }
        }
        /* Fix attribute namespacing */
        if( tree->type == XML_ELEMENT_NODE )
        {
                xmlElementPtr ele = (xmlElementPtr) tree;
                /* attributes is set to xmlAttributePtr,
                   but is an xmlAttrPtr??? */
                xmlAttrPtr attr = (xmlAttrPtr) ele->attributes;
                while( attr != NULL )
                {
                        _domReconcileNsAttr(attr, unused);
                        attr = attr->next;
                }
        }
        {
          /* Recurse through all child nodes */
          xmlNodePtr child = tree->children;
          while( child != NULL )
          {
              _domReconcileNs(child, unused);
              child = child->next;
            }
        }
}

void
domReconcileNs(xmlNodePtr tree)
{
        xmlNsPtr unused = NULL;
        _domReconcileNs(tree, &unused);
        if( unused != NULL )
                xmlFreeNsList(unused);
}

static xmlNodePtr
_domImportFrag(xmlNodePtr frag) {
    xmlNodePtr fraglist = frag->children;
    xmlNodePtr n = fraglist;

    frag->children = frag->last = NULL;
    // detach fragment list
    while ( n ){
      n->parent = NULL;
      n = n->next;
    }

    return fraglist;
}

static xmlNodePtr
_domReconcileSlice(xmlNodePtr head, xmlNodePtr tail) {
    xmlNodePtr cur = head;
    while ( cur ) {
        /* we must reconcile all nodes in the fragment */
        domReconcileNs(cur);
        if ( !tail || cur == tail ) {
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
 * i ran into a misconception here. there should be a normalization function
 * for the DOM, so sequences of text nodes can get replaced by a single
 * text node. as i see DOM Level 1 does not allow text node sequences, while
 * Level 2 and 3 do.
 **/
static xmlNodePtr
_domAddNodeToList(xmlNodePtr cur, xmlNodePtr leader, xmlNodePtr followup, xmlNodePtr *ptail)
{
  xmlNodePtr head = NULL, tail = NULL, p = NULL, n = NULL;
   if ( cur ) {
       head = tail = cur;
       if ( leader ) {
          p = leader->parent;
       }
       else if ( followup ) {
          p = followup->parent;
       }
       else {
          return 0; /* can't insert */
       }

       if (leader && followup && p != followup->parent) {
         warn("_domAddNodeToList(cur, prev, next, &frag) - 'prev' and 'next' have different parents");
       }

       if ( cur->type == XML_DOCUMENT_FRAG_NODE ) {
           head = _domImportFrag(cur);

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
   *ptail = NULL;
   return NULL;
}

/**
 * domIsParent tests, if testnode is parent of the reference
 * node. this test is very important to avoid circular constructs in
 * trees. if the ref is a parent of the cur node the
 * function returns 1 (TRUE), otherwise 0 (FALSE).
 **/
int
domIsParent( xmlNodePtr cur, xmlNodePtr refNode ) {
    xmlNodePtr helper = NULL;

    if ( cur == NULL || refNode == NULL) return 0;
    if (refNode==cur) return 1;
    if ( cur->doc != refNode->doc
         || refNode->children == NULL
         || cur->parent == (xmlNodePtr)cur->doc
         || cur->parent == NULL ) {
        return 0;
    }

    if( refNode->type == XML_DOCUMENT_NODE ) {
        return 1;
    }

    helper= cur;
    while ( helper && (xmlDocPtr) helper != cur->doc ) {
        if( helper == refNode ) {
            return 1;
        }
        helper = helper->parent;
    }

    return 0;
}

int
domTestHierarchy(xmlNodePtr cur, xmlNodePtr refNode)
{
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

int
domTestDocument(xmlNodePtr cur, xmlNodePtr refNode)
{
    if ( cur->type == XML_DOCUMENT_NODE ) {
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

int
domNodeIsReferenced(xmlNodePtr self) {

  xmlNodePtr cld;
  if (self->_private != NULL ) {
    return 1;
  }

  // Look for child references
  cld = self->children;
  while ( cld ) {
    if (domNodeIsReferenced( cld )) {
      return 1;
    }
    cld = cld->next;
  }

  return 0;
}

void
domReleaseNode( xmlNodePtr node ) {
    xmlUnlinkNode(node);
    if ( domNodeIsReferenced(node) == 0 ) {
        xmlFreeNode(node);
    }
}

xmlNodePtr
domImportNode( xmlDocPtr doc, xmlNodePtr node, int move, int reconcileNS ) {
    xmlNodePtr imported_node = node;

    if ( move ) {
        imported_node = node;
        xmlUnlinkNode( node );
    }
    else {
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

/**
 * Name: domName
 * Synopsis: string = domName( node );
 *
 * domName returns the full name for the current node.
 * If the node belongs to a namespace it returns the prefix and
 * the local name. otherwise only the local name is returned.
 **/
xmlChar*
domName(xmlNodePtr node) {
    const xmlChar *prefix = NULL;
    const xmlChar *name   = NULL;
    xmlChar *qname        = NULL;

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
    case XML_PI_NODE :
    case XML_NOTATION_NODE :
    case XML_NAMESPACE_DECL :
        name = node->name;
        break;

    case XML_COMMENT_NODE :
        name = (const xmlChar *) "#comment";
        break;

    case XML_CDATA_SECTION_NODE :
        name = (const xmlChar *) "#cdata-section";
        break;

    case XML_TEXT_NODE :
        name = (const xmlChar *) "#text";
        break;


    case XML_DOCUMENT_NODE :
    case XML_HTML_DOCUMENT_NODE :
    case XML_DOCB_DOCUMENT_NODE :
        name = (const xmlChar *) "#document";
        break;

    case XML_DOCUMENT_FRAG_NODE :
        name = (const xmlChar *) "#document-fragment";
        break;

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
        qname = xmlStrdup( prefix );
        qname = xmlStrcat( qname , (const xmlChar *) ":" );
        qname = xmlStrcat( qname , name );
    }
    else {
        qname = xmlStrdup( name );
    }

    return qname;
}

/**
 * Name: domAppendChild
 * Synopsis: xmlNodePtr domAppendChild( xmlNodePtr par, xmlNodePtr newCld );
 * @par: the node to append to
 * @newCld: the node to append
 *
 * Returns newCld on success otherwise NULL
 * The function will unbind newCld first if nesseccary. As well the
 * function will fail, if par or newCld is a Attribute Node OR if newCld
 * is a parent of par.
 *
 * If newCld belongs to a different DOM the node will be imported
 * implicit before it gets appended.
 **/
xmlNodePtr
domAppendChild( xmlNodePtr self,
                xmlNodePtr newChild ){
    xmlNodePtr head = newChild;
    xmlNodePtr tail = newChild;
    if ( self == NULL ) {
        return newChild;
    }

    if ( !(domTestHierarchy(self, newChild)
           && domTestDocument(self, newChild))){
        croak("appendChild: HIERARCHY_REQUEST_ERR");
    }

    if ( newChild->doc == self->doc ){
        xmlUnlinkNode( newChild );
    }
    else {
      //        xs_warn("WRONG_DOCUMENT_ERR - non conform implementation\n");
        /* xmlGenericError(xmlGenericErrorContext,"WRONG_DOCUMENT_ERR\n"); */
        newChild = domImportNode( self->doc, newChild, 1, 0 );
    }

    if ( self->children != NULL ) {
      head = _domAddNodeToList( newChild, self->last, NULL, &tail );
    }
    else if (newChild->type == XML_DOCUMENT_FRAG_NODE) {
        xmlNodePtr c1 = NULL;
        head = _domImportFrag(newChild);
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

    _domReconcileSlice(head, tail);
    return head;
}

xmlNodePtr
domRemoveChild( xmlNodePtr self, xmlNodePtr old ) {
    if ( self == NULL || old == NULL ) {
      return NULL;
    }
    if ( self != old->parent ) {
      /* not a child! */
      return NULL;
    }

    xmlUnlinkNode( old );
    if ( old->type == XML_ELEMENT_NODE ) {
      domReconcileNs( old );
    }

    return old ;
}

xmlNodePtr
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

    if ( old == NULL ) {
        domAppendChild( self, new );
        return old;
    }

    if ( !(domTestHierarchy(self, new)
           && domTestDocument(self, new))){
        croak("replaceChild: HIERARCHY_REQUEST_ERR");
    }

    if ( new->doc == self->doc ) {
        xmlUnlinkNode( new );
    }
    else {
        /* WRONG_DOCUMENT_ERR - non conform implementation */
        new = domImportNode( self->doc, new, 1, 1 );
    }

    if( old == self->children && old == self->last ) {
        domRemoveChild( self, old );
        domAppendChild( self, new );
    }
    else if ( new->type == XML_DOCUMENT_FRAG_NODE
              && new->children == NULL && 0) {
        /* want to replace with an empty fragment, then remove ... */
        head = NULL;
        domRemoveChild( self, old );
    }
    else {
        head = _domAddNodeToList(new, old->prev, old->next, &tail );
        old->parent = old->next = old->prev = NULL;
    }

    if ( head ) {
       _domReconcileSlice(head, tail);
    }

    return old;
}


xmlNodePtr
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
        if ( refChild->parent != self
             || (  newChild->type     == XML_DOCUMENT_FRAG_NODE
                   && newChild->children == NULL ) ) {
            /* NOT_FOUND_ERR */
            xmlGenericError(xmlGenericErrorContext,"NOT_FOUND_ERR\n");
            return NULL;
        }
    }

    if ( self->children == NULL ) {
        return domAppendChild( self, newChild );
    }

    if ( !(domTestHierarchy( self, newChild )
           && domTestDocument( self, newChild ))) {
        croak("insertBefore/insertAfter: HIERARCHY_REQUEST_ERR");
    }

    if ( self->doc == newChild->doc ){
        xmlUnlinkNode( newChild );
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

    return _domReconcileSlice(head, tail);
}

/*
 * this function does not exist in the spec although it's useful
 */
xmlNodePtr
domInsertAfter( xmlNodePtr self,
                xmlNodePtr newChild,
                xmlNodePtr refChild ){
    if ( refChild == NULL ) {
        return domInsertBefore( self, newChild, NULL );
    }
    return domInsertBefore( self, newChild, refChild->next );
}

xmlNodePtr
domReplaceNode( xmlNodePtr oldNode, xmlNodePtr newNode ) {
    xmlNodePtr prev = NULL, next = NULL, par = NULL;
    xmlNodePtr head = newNode;
    xmlNodePtr tail = newNode;

    if ( oldNode == NULL
         || newNode == NULL ) {
        /* NOT_FOUND_ERROR */
        return NULL;
    }

    if ( oldNode->type == XML_ATTRIBUTE_NODE
         || newNode->type == XML_ATTRIBUTE_NODE
         || newNode->type == XML_DOCUMENT_NODE
         || domIsParent( newNode, oldNode ) ) {
        /* HIERARCHY_REQUEST_ERR
         * wrong node type
         * new node is parent of itself
         */
        croak("replaceNode: HIERARCHY_REQUEST_ERR");
    }

    par  = oldNode->parent;
    prev = oldNode->prev;
    next = oldNode->next;

    xmlUnlinkNode( oldNode );

    if( prev == NULL && next == NULL ) {
        /* oldNode was the only child */
        domAppendChild( par , newNode );
    }
    else {
      head = _domAddNodeToList( newNode, prev,  next, &tail );
    }

    _domReconcileSlice(head, tail);

    return oldNode;
}

xmlNodePtr
domRemoveChildNodes( xmlNodePtr self) {
  xmlNodePtr frag = xmlNewDocFragment( self->doc );
  xmlNodePtr elem = self->children;
  // transfer kids
  frag->children = self->children;
  frag->last = self->last;
  self->children = self->last = NULL;
  while ( elem ) {
    xmlNodePtr next = elem->next;
    if (elem->type == XML_ATTRIBUTE_NODE
        || elem->type == XML_DTD_NODE) {
      domReleaseNode( elem );
    }
    elem = next;
  }
  return frag;
}

static void
_set_int_subset(xmlDocPtr doc, xmlNodePtr dtd) {
    xmlNodePtr old_dtd = (xmlNodePtr)doc->intSubset;
    if (old_dtd == dtd) {
        return;
    }

    if (old_dtd != NULL) {
        domReleaseNode(old_dtd);
    }

    doc->intSubset = (xmlDtdPtr)dtd;
}

xmlNodePtr
domAddSibling( xmlNodePtr self, xmlNodePtr nNode ) {

    xmlNodePtr rv = NULL;

    if ( nNode->type == XML_DOCUMENT_FRAG_NODE ) {
        croak("Adding document fragments with addSibling not yet supported!");
        return NULL;
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
            xmlFreeNode(copy);
        }
    }
    else {
        rv = xmlAddSibling( self, nNode );

        if ( rv && nNode->type == XML_DTD_NODE ) {
            _set_int_subset(self->doc, nNode);
        }
    }
    return rv;
}

xmlChar*
domGetNodeValue( xmlNodePtr n ) {
    xmlChar * retval = NULL;
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
            return retval;
            break;
        }
        if ( n->type != XML_ENTITY_DECL ) {
            retval = xmlXPathCastNodeToString(n);
        }
        else {
            if ( n->content != NULL ) {
                xs_warn(" duplicate content\n" );
                retval = xmlStrdup(n->content);
            }
            else if ( n->children != NULL ) {
                xmlNodePtr cnode = n->children;
                xs_warn(" use child content\n" );
                /* ok then toString in this case ... */
                while (cnode) {
                    xmlBufferPtr buffer = xmlBufferCreate();
                    /* buffer = xmlBufferCreate(); */
                    xmlNodeDump( buffer, n->doc, cnode, 0, 0 );
                    if ( buffer->content != NULL ) {
                        xs_warn( "add item" );
                        if ( retval != NULL ) {
                            retval = xmlStrcat( retval, buffer->content );
                        }
                        else {
                            retval = xmlStrdup( buffer->content );
                        }
                    }
                    xmlBufferFree( buffer );
                    cnode = cnode->next;
                }
            }
        }
    }

    return retval;
}

void
domSetNodeValue( xmlNodePtr n , xmlChar* val ){
    if ( n == NULL )
        return;
    if ( val == NULL ){
        val = (xmlChar *) "";
    }

    if( n->type == XML_ATTRIBUTE_NODE ){
      /* can't use xmlNodeSetContent - for Attrs it parses entities */
        if ( n->children != NULL ) {
            n->last = NULL;
            xmlFreeNodeList( n->children );
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


xmlNodeSetPtr
domGetChildrenByLocalName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = NULL;
    int any_name;

    if ( self != NULL && name != NULL ) {
        any_name = xmlStrcmp( name, (unsigned char*) "*" ) == 0;
        cld = self->children;
        while ( cld != NULL ) {
          if ( ((any_name && cld->type == XML_ELEMENT_NODE)
                || xmlStrcmp( name, cld->name ) == 0 )) {
                if ( rv == NULL ) {
                    rv = xmlXPathNodeSetCreate( cld ) ;
                }
                else {
                    xmlXPathNodeSetAdd( rv, cld );
                }
            }
            cld = cld->next;
        }
    }

    return rv;
}

static int _domNamecmp(xmlNodePtr self, const xmlChar *pname) {
  int rv;
  xmlChar *name = domName(self);
  rv = xmlStrcmp( name, pname );
  xmlFree(name);
  return rv;
}

xmlNodeSetPtr
domGetChildrenByTagName( xmlNodePtr self, xmlChar* name ){
    xmlNodeSetPtr rv = NULL;
    xmlNodePtr cld = NULL;
    int any_name;

    if ( self != NULL && name != NULL ) {
        any_name =  xmlStrcmp( name, (unsigned char *) "*" ) == 0;
        cld = self->children;
        while ( cld != NULL ) {
          if ( ((any_name && cld->type == XML_ELEMENT_NODE)
                || _domNamecmp( cld, name ) == 0 )) {
                if ( rv == NULL ) {
                    rv = xmlXPathNodeSetCreate( cld ) ;
                }
                else {
                    xmlXPathNodeSetAdd( rv, cld );
                }
            }
            cld = cld->next;
        }
    }

    return rv;
}


xmlNodeSetPtr
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
              xmlXPathNodeSetAdd( rv, cld );
            }
          }
          cld = cld->next;
        }
      }
    }

    return rv;
}

xmlNsPtr
domNewNs ( xmlNodePtr elem , xmlChar *prefix, xmlChar *href ) {
    xmlNsPtr ns = NULL;

    if (elem != NULL) {
        ns = xmlSearchNs( elem->doc, elem, prefix );
    }
    /* prefix is not in use */
    if (ns == NULL) {
        ns = xmlNewNs( elem , href , prefix );
    } else {
        /* prefix is in use; if it has same URI, let it go, otherwise it's
           an error */
        if (!xmlStrEqual(href, ns->href)) {
            ns = NULL;
        }
    }
    return ns;
}

xmlAttrPtr
domGetAttributeNode(xmlNodePtr node, const xmlChar *qname) {
    xmlChar * prefix    = NULL;
    xmlChar * localname = NULL;
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

xmlChar *
domGetAttribute(xmlNodePtr node, const xmlChar *qname) {
    xmlChar * prefix    = NULL;
    xmlChar * localname = NULL;
    xmlChar * rv = NULL;
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

xmlAttrPtr
domSetAttributeNode( xmlNodePtr node, xmlAttrPtr attr ) {
    if ( node == NULL || attr == NULL ) {
        return attr;
    }
    if ( attr != NULL && attr->type != XML_ATTRIBUTE_NODE )
        return NULL;
    if ( node == attr->parent ) {
        return attr; /* attribute is already part of the node */
    }
    if ( attr->doc != node->doc ){
        attr = (xmlAttrPtr) domImportNode( node->doc, (xmlNodePtr) attr, 1, 1 );
    }
    else {
        xmlUnlinkNode( (xmlNodePtr) attr );
    }

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

    return attr;
}

void
domAttrSerializeContent(xmlBufferPtr buffer, xmlAttrPtr attr)
{
    xmlNodePtr children;

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
}


int
domNodeNormalize( xmlNodePtr node );

int
domNodeNormalizeList( xmlNodePtr nodelist )
{
    while ( nodelist ){
        if ( domNodeNormalize( nodelist ) == 0 )
            return(0);
        nodelist = nodelist->next;
    }
    return(1);
}

int
domNodeNormalize( xmlNodePtr node )
{
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
        domNodeNormalizeList( (xmlNodePtr) node->properties );
    case XML_ATTRIBUTE_NODE:
    case XML_DOCUMENT_NODE:
        return( domNodeNormalizeList( node->children ) );
        break;
    default:
        break;
    }
    return(1);
}

int
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

xmlAttrPtr
domCreateAttribute( xmlDocPtr self, unsigned char *name, unsigned char *value) {
  xmlChar *buffer;
  xmlAttrPtr newAttr;
  /* unlike xmlSetProp, xmlNewDocProp does not encode entities in value */
  buffer = xmlEncodeEntitiesReentrant(self, value);
  newAttr = xmlNewDocProp( self, name, buffer );
  xmlFree(buffer);
  return newAttr;
}

xmlAttrPtr
domCreateAttributeNS( xmlDocPtr self, unsigned char *URI, unsigned char *name, unsigned char *value ) {
  xmlChar * prefix = NULL;
  xmlChar * localname = NULL;
  xmlAttrPtr newAttr = NULL;
  xmlNsPtr ns = NULL;
  xmlNodePtr root = xmlDocGetRootElement(self);

  if ( URI != NULL && xmlStrlen(URI) > 0 ) {
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
      croak("unable to create Attribute namespace");
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

xmlAttrPtr
domSetAttributeNS(xmlNodePtr self, xmlChar *nsURI, xmlChar *name, xmlChar *value ) {
  xmlNsPtr   ns          = NULL;
  xmlChar    * localname = NULL;
  xmlChar    * prefix    = NULL;
  xmlAttrPtr newAttr     = NULL;

  if (self && nsURI && xmlStrlen(nsURI) && name && value) {

    localname =  xmlSplitQName2(name, &prefix);
    if ( localname ) {
      name = localname;
    }

    ns = xmlSearchNsByHref( self->doc, self, nsURI );
    if ( ns == NULL ) {
      /* create a new NS if the NS does not already exists */
      ns = xmlNewNs(self, nsURI , prefix );
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
