#include "xml6.h"
#include "xml6_ctx.h"

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr ctx, xmlSAXHandlerPtr sax) {
  if (ctx) {
    ctx->sax = sax;
  }
  else {
    fprintf(stderr, "can't set SAX handler in this context\n");
  }
}

