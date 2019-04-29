#include "xml6.h"
#include "xml6_input.h"

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr self, char *url) {
  if (self == NULL) xml6_fail("can't assign filename to NULL parser-input struct");

  if (self->filename) xmlFree((xmlChar*)self->filename);
  self->filename = xmlStrdup((const xmlChar *) url);
}

DLLEXPORT int xml6_input_buffer_push_str(xmlParserInputBufferPtr buffer, const xmlChar* str) {
  xmlChar* new_string = NULL;
  int len;
  if (buffer == NULL) return xml6_warn("can't push to NULL parser input buffer");
  if (str == NULL) return xml6_warn("can't push NULL string to parser input buffer");

  new_string = xmlStrdup(str);
  len = xmlStrlen(new_string);
  return xmlParserInputBufferPush(buffer, len, (const char*)new_string);
}
