#ifndef __XML6_NODE_H
#define __XML6_NODE_H

#include <libxml/parser.h>

DLLEXPORT void xml6_node_set_doc(xmlNodePtr, xmlDocPtr);
DLLEXPORT void xml6_node_set_ns(xmlNodePtr, xmlNsPtr);

#endif /* __XML6_NODE_H */
