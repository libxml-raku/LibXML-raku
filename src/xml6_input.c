#include "xml6.h"
#include "xml6_input.h"
#include <assert.h>

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr self, char *url) {
    assert(self != NULL);
    if (self->filename) xmlFree((xmlChar*)self->filename);
    self->filename = (char*) xmlStrdup((const xmlChar *) url);
}

DLLEXPORT int xml6_input_buffer_push_str(xmlParserInputBufferPtr buffer, const xmlChar* str) {
    xmlChar* new_string = NULL;
    int len;

    assert(buffer != NULL);
    assert(str != NULL);

    new_string = xmlStrdup(str);
    len = xmlStrlen(new_string);

    return xmlParserInputBufferPush(buffer, len, (const char*)new_string);
}
