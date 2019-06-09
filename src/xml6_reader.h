#ifndef __XML6_READER_H
#define __XML6_READER_H

#include "xml6.h"
#include <libxml/xmlreader.h>

DLLEXPORT int
xml6_reader_next_sibling(xmlTextReaderPtr self);

#endif /* __XML6_READER_H */
