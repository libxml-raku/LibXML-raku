#include "xml6.h"
#include "xml6_input.h"

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr input, char *url) {
  if (input == NULL) xml6_fail("can't assign filename to NULL parser-input struct");

  if (input->filename) xmlFree((xmlChar*)input->filename);
  input->filename = url ? (char *) xmlStrdup((const xmlChar *) url) : NULL;
}
