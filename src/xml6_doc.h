#ifndef __XML6_DOC_H
#define __XML6_DOC_H

#include <libxml/parser.h>

DLLEXPORT void xml6_doc_set_encoding(xmlDocPtr, char* enc);
DLLEXPORT void xml6_doc_set_URI(xmlDocPtr, char* URI) ;
DLLEXPORT void xml6_doc_set_version(xmlDocPtr, char*);
DLLEXPORT int xml6_doc_set_flags(xmlDocPtr, int);
DLLEXPORT int xml6_doc_get_flags(xmlDocPtr);

#endif /* __XML6_DOC_H */
