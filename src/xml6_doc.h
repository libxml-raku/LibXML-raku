#ifndef __XML6_DOC_H
#define __XML6_DOC_H

#include <libxml/parser.h>

DLLEXPORT void xml6_doc_set_int_subset(xmlDocPtr doc, xmlDtdPtr dtd);
DLLEXPORT void xml6_doc_set_uri(xmlDocPtr doc, char *uri) ;

#endif /* __XML6_DOC_H */
