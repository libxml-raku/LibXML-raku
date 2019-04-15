#ifndef __LIBXML_DOM_XPATH_H__
#define __LIBXML_DOM_XPATH_H__

#include <libxml/tree.h>
#include <libxml/xpath.h>
#include "xml6.h"

void
perlDocumentFunction( xmlXPathParserContextPtr ctxt, int nargs );

xmlNodeSetPtr
domXPathSelect( xmlNodePtr refNode, xmlChar* xpathstring );

void
domReferenceXPathObject(xmlXPathObjectPtr);

void
domReleaseXPathObject(xmlXPathObjectPtr);

xmlXPathObjectPtr
domXPathFind( xmlNodePtr refNode, xmlChar* xpathstring, int to_bool );

xmlNodeSetPtr
domXPathCompSelect( xmlNodePtr refNode, xmlXPathCompExprPtr comp );

xmlXPathContextPtr
domXPathNewCtxt(xmlNodePtr refNode);

void
domXPathFreeCtxt(xmlXPathContextPtr ctxt);

xmlXPathObjectPtr
domXPathCompFind( xmlNodePtr refNode, xmlXPathCompExprPtr comp, int to_bool );

xmlNodeSetPtr
domXPathSelectCtxt( xmlXPathContextPtr ctxt, xmlChar* xpathstring );

xmlXPathObjectPtr
domXPathFindCtxt( xmlXPathContextPtr ctxt, xmlChar* xpathstring, int to_bool );

xmlXPathObjectPtr
domXPathCompFindCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, int to_bool );

void
domReferenceNodeSet(xmlNodeSetPtr self);

void
domReleaseNodeSet(xmlNodeSetPtr self);

#endif
