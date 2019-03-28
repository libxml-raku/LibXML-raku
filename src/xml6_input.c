#include "xml6.h"
#include "xml6_input.h"

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr self, char *url) {
  if (self == NULL) xml6_fail("can't assign filename to NULL parser-input struct");

  if (self->filename) xmlFree((xmlChar*)self->filename);
  self->filename = url ? (char *) xmlStrdup((const xmlChar *) url) : NULL;
}

DLLEXPORT int xml6_input__buffer_push(xmlParserInputBufferPtr buffer, char *str) {
  xmlChar* new_string = NULL;
  if (buffer == NULL) return xml6_warn("can't push to NULL parser input buffer");
  if (str == NULL) return xml6_warn("can't push NULL string to parser input buffer");

  new_string = xmlStrdup((const xmlChar*) str);
  return xmlParserInputBufferPush(buffer, xmlStrlen(new_string), (const char*)new_string);
}
