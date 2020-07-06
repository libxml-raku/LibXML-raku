#ifndef __LIBXML_DOM_XPATH_H__
#define __LIBXML_DOM_XPATH_H__

#include <libxml/tree.h>
#include <libxml/xpath.h>
#include "xml6.h"

DLLEXPORT void
perlDocumentFunction(xmlXPathParserContextPtr ctxt, int nargs);

DLLEXPORT xmlNodeSetPtr
domXPathGetNodeSet(xmlXPathObjectPtr, int select);

DLLEXPORT xmlXPathObjectPtr
domXPathNewPoint(xmlNodePtr node, int);

DLLEXPORT xmlNodeSetPtr
domXPathSelectStr( xmlNodePtr refNode, xmlChar* xpathstring );

DLLEXPORT xmlNodeSetPtr
domXPathSelect( xmlNodePtr refNode, xmlXPathCompExprPtr comp );

DLLEXPORT xmlNodePtr
domXPathCtxtSetNode(xmlXPathContextPtr, xmlNodePtr);

DLLEXPORT xmlXPathContextPtr
domXPathNewCtxt(xmlNodePtr refNode);

DLLEXPORT void
domSetXPathCtxtErrorHandler(xmlXPathContextPtr, xmlStructuredErrorFunc);

DLLEXPORT void
domXPathFreeCtxt(xmlXPathContextPtr);

xmlXPathObjectPtr
domXPathFind( xmlNodePtr refNode, xmlXPathCompExprPtr comp, int to_bool );

xmlXPathObjectPtr
domXPathFindCtxt( xmlXPathContextPtr ctxt, xmlXPathCompExprPtr comp, xmlNodePtr refNode, int to_bool );

DLLEXPORT void
domReferenceNodeSet(xmlNodeSetPtr self);

DLLEXPORT void
domUnreferenceNodeSet(xmlNodeSetPtr self);

DLLEXPORT void domPushNodeSet(xmlNodeSetPtr self, xmlNodePtr elem, int reference);

DLLEXPORT xmlNodeSetPtr domCreateNodeSetFromList(xmlNodePtr elem, int keep_blanks);

DLLEXPORT xmlNodePtr domPopNodeSet(xmlNodeSetPtr self);

DLLEXPORT int domDeleteNodeSetItem(xmlNodeSetPtr self, xmlNodePtr item);

DLLEXPORT xmlNodeSetPtr domCopyNodeSet(xmlNodeSetPtr);

DLLEXPORT xmlNodeSetPtr domReverseNodeSet(xmlNodeSetPtr);

DLLEXPORT xmlNodeSetPtr domXPathSelectCtxt(xmlXPathContextPtr, xmlXPathCompExprPtr, xmlNodePtr refNode);

#endif
