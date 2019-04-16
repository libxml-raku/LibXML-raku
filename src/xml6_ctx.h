#ifndef __XML6_CTX_H
#define __XML6_CTX_H

#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>
#include <libxml/xmlerror.h>

DLLEXPORT void xml6_ctx_add_reference(xmlParserCtxtPtr);
DLLEXPORT int xml6_ctx_remove_reference(xmlParserCtxtPtr);
DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr, xmlSAXHandlerPtr);
DLLEXPORT htmlParserCtxtPtr xml6_ctx_html_create(const xmlChar *buf, const char *en);

#endif /* __XML6_CTX_H */
