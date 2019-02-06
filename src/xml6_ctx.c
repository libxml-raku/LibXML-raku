#include "xml6.h"
#include "xml6_ctx.h"

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr self, xmlSAXHandlerPtr sax) {
  if (self == NULL) xml6_fail("can't assign SAX handler to NULL context");

  self->sax = sax;
}
