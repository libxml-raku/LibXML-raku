#include "xml6.h"
#include "xml6_input.h"

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr self, char *url) {
  if (self == NULL) xml6_fail("can't assign filename to NULL parser-input struct");

  if (self->filename) xmlFree((xmlChar*)self->filename);
  self->filename = url ? (char *) xmlStrdup((const xmlChar *) url) : NULL;
}
