#ifndef __XML6_DOC_FRAG_H
#define __XML6_DOC_FRAG_H

#include <libxml/parser.h>

DLLEXPORT void xml6_doc_set_int_subset(xmlDocPtr doc, xmlDtdPtr dtd);

// To be assessed from Perl 5 port
#define PmmPROXYNODE(x) (x->_private)

#endif /* __XML6_DOC_FRAG_H */
