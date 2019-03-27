#include "xml6.h"
#include "xml6_input.h"

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr self, char *url) {
  if (self == NULL) xml6_fail("can't assign filename to NULL parser-input struct");

  if (self->filename) xmlFree((xmlChar*)self->filename);
  self->filename = url ? (char *) xmlStrdup((const xmlChar *) url) : NULL;
}

DLLEXPORT int xml6_input_push(xmlParserInputPtr self, char *str) {
  xmlChar* new_string = NULL;
  if (self == NULL) xml6_fail("can't push to NULL parser-input struct");
  if (str == NULL) xml6_fail("can't push NULL string to parser-input struct");

  new_string = xmlStrdup((const xmlChar*) str);
  return xmlParserInputBufferPush(self, xmlStrlen(new_string), (const char*)new_string);
}
