#ifndef __XML6_NODE_H
#define __XML6_NODE_H

#include <libxml/parser.h>

DLLEXPORT void xml6_node_add_reference(xmlNodePtr);
DLLEXPORT int xml6_node_remove_reference(xmlNodePtr);

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr);
DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr node, int blank);
DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr, int);
DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr, int);
DLLEXPORT void xml6_node_set_doc(xmlNodePtr, xmlDocPtr);
DLLEXPORT void xml6_node_set_ns(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_content(xmlNodePtr, xmlChar*);

#endif /* __XML6_NODE_H */
