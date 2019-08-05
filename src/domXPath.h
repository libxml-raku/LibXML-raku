#ifndef __LIBXML_DOM_XPATH_H__
#define __LIBXML_DOM_XPATH_H__

#include <libxml/tree.h>
#include <libxml/xpath.h>
#include "xml6.h"

void
perlDocumentFunction( xmlXPathParserContextPtr ctxt, int nargs );

xmlNodeSetPtr
domXPathGetNodeSet(xmlXPathObjectPtr, int select);

xmlNodeSetPtr
domXPathSelectStr( xmlNodePtr refNode, xmlChar* xpathstring );

xmlNodeSetPtr
domXPathSelect( xmlNodePtr refNode, xmlXPathCompExprPtr comp );

xmlNodePtr
domXPathCtxtSetNode(xmlXPathContextPtr, xmlNodePtr);

xmlXPathContextPtr
domXPathNewCtxt(xmlNodePtr refNode);

void
domXPathFreeCtxt(xmlXPathContextPtr ctxt);

xmlXPathObjectPtr
domXPathFind( xmlNodePtr refNode, xmlXPathCompExprPtr comp, int to_bool );

xmlXPathObjectPtr
domXPathFindCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode, int to_bool );

void
domReferenceNodeSet(xmlNodeSetPtr self);

DLLEXPORT void domPushNodeSet(xmlNodeSetPtr self, xmlNodePtr elem);

DLLEXPORT xmlNodePtr domPopNodeSet(xmlNodeSetPtr self);

DLLEXPORT xmlNodeSetPtr domCopyNodeSet(xmlNodeSetPtr);

void
domUnreferenceNodeSet(xmlNodeSetPtr self);

xmlNodeSetPtr
domXPathSelectCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode);

#endif
