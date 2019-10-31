#ifndef __XML6_NS_H
#define __XML6_NS_H

#include <libxml/parser.h>

DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr);
DLLEXPORT xmlChar* xml6_ns_unique_key(xmlNsPtr);

#endif /* __XML6_NS_H */
