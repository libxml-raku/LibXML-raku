#ifndef __XML6_NODE_H
#define __XML6_NODE_H

#include <libxml/parser.h>
#include "libxml/xpath.h"

DLLEXPORT void xml6_node_add_reference(xmlNodePtr);
DLLEXPORT int xml6_node_remove_reference(xmlNodePtr);

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr);
DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr, int blank);
DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr, int);
DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr, int);
DLLEXPORT void xml6_node_set_doc(xmlNodePtr, xmlDocPtr);
DLLEXPORT void xml6_node_set_ns(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_content(xmlNodePtr, xmlChar*);
DLLEXPORT xmlChar* xml6_node_to_buf(xmlNodePtr, int opts, size_t* len, char* enc);
DLLEXPORT xmlChar* xml6_node_to_str(xmlNodePtr, int opts);
DLLEXPORT xmlChar* xml6_node_to_str_C14N(xmlNodePtr, int comments, int exclusive, xmlChar** inc_prefix_list, xmlNodeSetPtr nodelist);
DLLEXPORT xmlNodeSetPtr xml6_node_list_to_nodeset(xmlNodePtr, int keep_blanks);

#endif /* __XML6_NODE_H */
