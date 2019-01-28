#include "xml6.h"
#include "xml6_ctx.h"

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr ctx, xmlSAXHandlerPtr sax) {
  if (ctx) {
    ctx->sax = sax;
  }
  else {
    fprintf(stderr, "%s:%d: can't set SAX handler to NULL context\n", __FILE__, __LINE__);
  }
}

