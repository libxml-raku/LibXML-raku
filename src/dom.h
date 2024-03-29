/* dom.h
 * $Id$
 * Author: Christian Glahn (2001)
 * Ported from Perl to Raku by David Warring (2019)
 *
 * This header file provides some definitions for dom wrapper functions.
 *
 */

#ifndef __LIBXML_DOM_H__
#define __LIBXML_DOM_H__

#ifdef __cplusplus
extern "C" {
#endif

#include <libxml/tree.h>
#include <libxml/xpath.h>
#include <libxml/encoding.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/xmlIO.h>
#include <libxml/xpathInternals.h>
#include <libxml/globals.h>
#include <stdio.h>

#ifdef __cplusplus
}
#endif

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

/**
 * part 0:
 *
 * unsortet.
 **/


#define XML_XMLNS_NS (xmlChar*)"http://www.w3.org/2000/xmlns/"

DLLEXPORT void
domUnlinkNode(xmlNodePtr self);

DLLEXPORT void
domReconcileNS(xmlNodePtr tree);

DLLEXPORT xmlDtdPtr
domGetInternalSubset(xmlDocPtr self);

DLLEXPORT xmlDtdPtr
domGetExternalSubset(xmlDocPtr self);

DLLEXPORT xmlDtdPtr
domSetInternalSubset(xmlDocPtr, xmlDtdPtr dtd);

DLLEXPORT xmlDtdPtr
domSetExternalSubset(xmlDocPtr, xmlDtdPtr dtd);

DLLEXPORT xmlEntityPtr
domGetEntityFromDtd(xmlDtdPtr dtd, xmlChar *name);

DLLEXPORT xmlEntityPtr
domGetParameterEntityFromDtd(xmlDtdPtr dtd, xmlChar *name);
/**
 * NAME domIsParent
 * TYPE function
 *
 * tests if a node is an ancestor of another node
 *
 * SYNOPSIS
 * if ( domIsParent(cur, ref) ) ...
 *
 * this function is very useful to resolve if an operation would cause
 * circular references.
 *
 * the function returns 1 if the ref node is a parent of the cur node.
 */
DLLEXPORT int
domIsParent( xmlNodePtr cur, xmlNodePtr ref );

/**
 * NAME _domCanInsert
 * TYPE function
 *
 * tests the general hierarchy error
 *
 * SYNOPSIS
 * if ( _domCanInsert(cur, ref) ) ...
 *
 * this function tests the general hierarchy error.
 * it tests if the ref node would cause any hierarchical error for
 * cur node. the function evaluates domIsParent() internally.
 *
 * the function will retrun 1 if there is no hierarchical error found.
 * otherwise it returns 0.
 */
DLLEXPORT int
_domCanInsert( xmlNodePtr cur, xmlNodePtr ref );

/**
 * NAME domTestDocument
 * TYPE function
 * SYNOPSIS
 * if ( domTestDocument(cur, ref) )...
 *
 * this function extends the _domCanInsert() function. It tests if the
 * cur node is a document and if so, it will check if the ref node can be
 * inserted. (e.g. Attribute or Element nodes must not be appended to a
 * document node)
 */
DLLEXPORT int
domTestDocument( xmlNodePtr cur, xmlNodePtr ref );

DLLEXPORT const xmlChar*
domGetNodeName( xmlNodePtr node);

DLLEXPORT const xmlChar*
domGetXPathKey( xmlNodePtr node);

DLLEXPORT const xmlChar*
domGetASTKey( xmlNodePtr node);

DLLEXPORT void
domSetNodeName(xmlNodePtr self , xmlChar *string);

DLLEXPORT xmlNodePtr
domAppendChild( xmlNodePtr self,
                xmlNodePtr newChild );

DLLEXPORT xmlNodePtr
domAppendTextChild( xmlNodePtr self, unsigned char *name, unsigned char *value);

DLLEXPORT xmlNodePtr
domReplaceChild( xmlNodePtr self,
                 xmlNodePtr newChlid,
                 xmlNodePtr oldChild );
DLLEXPORT xmlNodePtr
domRemoveChild( xmlNodePtr self,
               xmlNodePtr Child );
xmlNodePtr
domInsertBefore( xmlNodePtr self,
                 xmlNodePtr newChild,
                 xmlNodePtr refChild );

DLLEXPORT xmlNodePtr
domInsertAfter( xmlNodePtr self,
                xmlNodePtr newChild,
                xmlNodePtr refChild );

/* A.3 extra functionality not specified in DOM L1/2*/
DLLEXPORT xmlChar*
domGetNodeValue( xmlNodePtr self );

DLLEXPORT void
domSetNodeValue( xmlNodePtr self, xmlChar* value );

DLLEXPORT xmlNodePtr
domReplaceNode( xmlNodePtr old, xmlNodePtr new );

DLLEXPORT xmlNodePtr
domRemoveChildNodes( xmlNodePtr self);

DLLEXPORT xmlNodePtr
domAddSibling( xmlNodePtr self, xmlNodePtr nNode );

DLLEXPORT int
domNodeIsReferenced(xmlNodePtr self);

DLLEXPORT void
domReleaseNode( xmlNodePtr node );

/**
 * NAME domImportNode
 * TYPE function
 * SYNOPSIS
 * node = domImportNode( document, node, move, reconcileNS);
 *
 * the function will import a node to the given document. it will work safe
 * with namespaces and subtrees.
 *
 * if move is set to 1, then the node will be entirely removed from its
 * original document. if move is set to 0, the node will be copied with the
 * deep option.
 *
 * if reconcileNS is 1, namespaces are reconciled.
 *
 * the function will return the imported node on success. otherwise NULL
 * is returned
 */
DLLEXPORT xmlNodePtr
domImportNode( xmlDocPtr document, xmlNodePtr node, int move, int reconcileNS );

DLLEXPORT xmlElementType
domNodeType(xmlChar* name);

DLLEXPORT xmlNodeSetPtr
domGetChildrenByLocalName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagNameNS( xmlNodePtr self, xmlChar* nsURI, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetElementsByLocalName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetElementsByTagName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetElementsByTagNameNS( xmlNodePtr self, xmlChar* nsURI, xmlChar* name );

DLLEXPORT xmlAttrPtr
domGetAttributeNode( xmlNodePtr node, const xmlChar* qname);

DLLEXPORT int
domHasAttributeNS(xmlNodePtr self, const xmlChar* nsURI, const xmlChar* name);

DLLEXPORT const xmlChar*
domGetNamespaceDeclURI(xmlNodePtr self, const xmlChar* prefix );

DLLEXPORT int
domSetNamespaceDeclPrefix(xmlNodePtr self, xmlChar* prefix, xmlChar* new_prefix );

DLLEXPORT const xmlChar*
domGetAttributeNS(xmlNodePtr self, const xmlChar* nsURI, const xmlChar* name);

DLLEXPORT xmlAttrPtr
domGetAttributeNodeNS(xmlNodePtr, const xmlChar* nsURI, const xmlChar* name);

DLLEXPORT xmlChar*
domGetAttribute(xmlNodePtr node, const xmlChar* qname);

DLLEXPORT int
domSetAttribute( xmlNodePtr self, xmlChar* name, xmlChar* value );

DLLEXPORT xmlAttrPtr
domSetAttributeNode( xmlNodePtr node , xmlAttrPtr attr );

DLLEXPORT xmlAttrPtr
domSetAttributeNodeNS( xmlNodePtr node , xmlAttrPtr attr );

DLLEXPORT const xmlChar*
domGenNsPrefix(xmlNodePtr self, xmlChar* base);

DLLEXPORT int
domNormalize( xmlNodePtr node );

DLLEXPORT int
domNormalizeList( xmlNodePtr nodelist );

DLLEXPORT int
domRemoveNsRefs(xmlNodePtr tree, xmlNsPtr ns);

DLLEXPORT xmlChar*
domAttrSerializeContent(xmlAttrPtr attr);

DLLEXPORT void
domClearPSVI(xmlNodePtr tree);

DLLEXPORT xmlAttrPtr
domCreateAttribute( xmlDocPtr, unsigned char *name, unsigned char *value);

DLLEXPORT xmlAttrPtr
domCreateAttributeNS( xmlDocPtr, unsigned char *URI, unsigned char *name, unsigned char *value );

DLLEXPORT xmlAttrPtr
domSetAttributeNS(xmlNodePtr, xmlChar* URI, xmlChar* name, xmlChar* value );

DLLEXPORT int
domSetNamespace(xmlNodePtr, xmlChar* nsURI, xmlChar* nsPrefix, int activate);

DLLEXPORT xmlNodePtr
domAddNewChild( xmlNodePtr self, xmlChar* nsURI, xmlChar* name );

DLLEXPORT xmlChar* domFailure(xmlNodePtr);

DLLEXPORT xmlChar* domUniqueKey(void*);

DLLEXPORT int domIsSameNode(void*, void *);

#endif
