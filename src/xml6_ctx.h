#ifndef __XML6_CTX_H
#define __XML6_CTX_H

#include <libxml/parser.h>

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr ctx, xmlSAXHandlerPtr sax);

#endif /* __XML6_CTX_H */
