#ifndef __XML6_DOC_H
#define __XML6_DOC_H

#include <libxml/parser.h>

DLLEXPORT void xml6_doc_set_encoding(xmlDocPtr, char *enc);
DLLEXPORT void xml6_doc_set_intSubset(xmlDocPtr, xmlDtdPtr dtd);
DLLEXPORT void xml6_doc_set_URI(xmlDocPtr, char *URI) ;
DLLEXPORT void xml6_doc_set_version(xmlDocPtr, char *);

#endif /* __XML6_DOC_H */
