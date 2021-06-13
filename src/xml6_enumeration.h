#ifndef __XML6_ENUMERATION_H
#define __XML6_ENUMERATION_H

#include <libxml/tree.h>

DLLEXPORT xmlChar* xml6_enumeration_to_string(xmlEnumerationPtr);
DLLEXPORT int xml6_enumeration_accepts(xmlEnumerationPtr, xmlChar*);

#endif /* __XML6_ENUMERATION_H */
