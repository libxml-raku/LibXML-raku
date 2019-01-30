#include "xml6.h"
#include "xml6_ctx.h"

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr ctx, xmlSAXHandlerPtr sax) {
  if (ctx == NULL) xml6_fail("can't assign SAX handler to NULL context");

  ctx->sax = sax;
}

