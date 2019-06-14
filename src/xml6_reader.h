#ifndef __XML6_READER_H
#define __XML6_READER_H

#include "xml6.h"
#include <libxml/xmlreader.h>
#include <libxml/pattern.h>

DLLEXPORT int
xml6_reader_next_sibling(xmlTextReaderPtr self);

DLLEXPORT int
xml6_reader_next_element(xmlTextReaderPtr self, char *, char *);

DLLEXPORT int
xml6_reader_next_sibling_element(xmlTextReaderPtr self, char *name, char *URI);

DLLEXPORT int
xml6_reader_skip_siblings(xmlTextReaderPtr self);

DLLEXPORT int
xml6_reader_finish(xmlTextReaderPtr self);

DLLEXPORT int
xml6_reader_next_pattern_match(xmlTextReaderPtr self, xmlPatternPtr compiled) ;

#endif /* __XML6_READER_H */
