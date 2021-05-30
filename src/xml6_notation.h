#ifndef __XML6_NOTATION_H
#define __XML6_NOTATION_H

#include <libxml/parser.h>

DLLEXPORT xmlNotationPtr xml6_notation_copy(xmlNotationPtr);
DLLEXPORT xmlChar* xml6_notation_unique_key(xmlNotationPtr);
DLLEXPORT xmlNotationPtr xml6_notation_create(const xmlChar*, const xmlChar*, const xmlChar*);
DLLEXPORT void xml_notation_free(xmlNotationPtr);
#endif /* __XML6_NOTATION_H */
