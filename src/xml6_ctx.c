#include "xml6.h"
#include "xml6_ctx.h"
#include "xml6_ref.h"

DLLEXPORT void xml6_ctx_add_reference(xmlParserCtxtPtr self) {
  xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_ctx_remove_reference(xmlParserCtxtPtr self) {
  return xml6_ref_remove( &(self->_private), "parser context", (void*) self );
}

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr self, xmlSAXHandlerPtr sax) {
  if (self == NULL) xml6_fail("can't assign SAX handler to NULL context");

  self->sax = sax;
}
