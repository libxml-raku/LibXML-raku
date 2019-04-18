#ifndef __XML6_NS_H
#define __XML6_NS_H

#include <libxml/parser.h>

DLLEXPORT void xml6_ns_add_reference(xmlNsPtr);
DLLEXPORT int xml6_ns_remove_reference(xmlNsPtr);
DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr);

#endif /* __XML6_NS_H */
