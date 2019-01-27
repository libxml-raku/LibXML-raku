#include "xml6.h"
#include "xml6_ctx.h"

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr ctx, xmlSAXHandlerPtr sax) {
  ctx->sax = sax;
}

