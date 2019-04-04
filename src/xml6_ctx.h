#ifndef __XML6_CTX_H
#define __XML6_CTX_H

#include <libxml/parser.h>

DLLEXPORT void xml6_ctx_add_reference(xmlParserCtxtPtr);
DLLEXPORT int xml6_ctx_remove_reference(xmlParserCtxtPtr self);
DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr, xmlSAXHandlerPtr);

#endif /* __XML6_CTX_H */
