#ifndef __XML6_PARSER_CTX_H
#define __XML6_PARSER_CTX_H

#include <libxml/parser.h>
#include <libxml/parserInternals.h>
#include <libxml/HTMLparser.h>

DLLEXPORT void xml6_parser_ctx_add_reference(xmlParserCtxtPtr);
DLLEXPORT int xml6_parser_ctx_remove_reference(xmlParserCtxtPtr);
DLLEXPORT void xml6_parser_ctx_set_sax(xmlParserCtxtPtr, xmlSAXHandlerPtr);
DLLEXPORT htmlParserCtxtPtr xml6_parser_ctx_html_create_str(const xmlChar *str, const char *en);
DLLEXPORT htmlParserCtxtPtr xml6_parser_ctx_html_create_buf(const xmlChar *buf, int len, const char *en);
DLLEXPORT int xml6_parser_ctx_close(xmlParserCtxtPtr self);

#endif /* __XML6_PARSER_CTX_H */
