/* dom.h
 * $Id$
 * Author: Christian Glahn (2001)
 * Ported from Perl 5 to 6 by David Warring (2019)
 *
 * This header file provides some definitions for wrapper functions.
 * These functions hide most of libxml2 code, and should make the
 * code in the XS file more readable .
 *
 * The Functions are sorted in four parts:
 * part 0 ..... general wrapper functions which do not belong
 *              to any of the other parts and not specified in DOM.
 * part A ..... wrapper functions for general node access
 * part B ..... document wrapper
 * part C ..... element wrapper
 *
 * I did not implement any Text, CDATASection or comment wrapper functions,
 * since it is pretty straight-forward to access these nodes.
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

DLLEXPORT void
domReconcileNS(xmlNodePtr tree);

DLLEXPORT xmlDtdPtr
domGetInternalSubset(xmlDocPtr self);

DLLEXPORT xmlDtdPtr
domGetExternalSubset(xmlDocPtr self);

DLLEXPORT void
domSetInternalSubset(xmlDocPtr, xmlDtdPtr dtd);

DLLEXPORT void
domSetExternalSubset(xmlDocPtr, xmlDtdPtr dtd);

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

/**
 * part A:
 *
 * class Node
 **/

/* A.1 DOM specified section */

DLLEXPORT xmlChar*
domName( xmlNodePtr node );

DLLEXPORT void
domSetName( xmlNodePtr node, xmlChar* name );

DLLEXPORT xmlNodePtr
domAppendChild( xmlNodePtr self,
                xmlNodePtr newChild );

DLLEXPORT void
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
 * part B:
 *
 * class Document
 **/

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

/**
 * part C:
 *
 * class Element
 **/

DLLEXPORT xmlNodeSetPtr
domGetChildrenByLocalName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagName( xmlNodePtr self, xmlChar* name );

DLLEXPORT xmlNodeSetPtr
domGetChildrenByTagNameNS( xmlNodePtr self, xmlChar* nsURI, xmlChar* name );

DLLEXPORT xmlAttrPtr
domGetAttributeNode( xmlNodePtr node, const xmlChar *qname);

DLLEXPORT int
domHasAttributeNS(xmlNodePtr self, const xmlChar *nsURI, const xmlChar *name);

DLLEXPORT xmlAttrPtr
domGetAttributeNodeNS(xmlNodePtr sef, const xmlChar *nsURI, const xmlChar *name);

DLLEXPORT xmlChar*
domGetAttribute(xmlNodePtr node, const xmlChar *qname);

DLLEXPORT xmlAttrPtr
domSetAttributeNode( xmlNodePtr node , xmlAttrPtr attr );

DLLEXPORT xmlAttrPtr
domSetAttributeNodeNS( xmlNodePtr node , xmlAttrPtr attr );

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
domSetAttributeNS(xmlNodePtr, xmlChar *URI, xmlChar *name, xmlChar *value );

DLLEXPORT int
domSetNamespace(xmlNodePtr, xmlChar* nsURI, xmlChar* nsPrefix);

DLLEXPORT char *dom_error;

#endif
