#ifndef __XML6_INPUT_H
#define __XML6_INPUT_H

#include <libxml/parser.h>

DLLEXPORT void xml6_input_set_filename(xmlParserInputPtr, char *url);

DLLEXPORT int xml6_input_buffer_push_str(xmlParserInputBufferPtr, const xmlChar* str);

#endif /* __XML6_INPUT_H */
