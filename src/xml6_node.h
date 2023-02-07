#ifndef __XML6_NODE_H
#define __XML6_NODE_H

#include <libxml/parser.h>
#include "libxml/xpath.h"
#include "libxml/c14n.h"

DLLEXPORT void xml6_node_add_reference(xmlNodePtr);
DLLEXPORT int xml6_node_remove_reference(xmlNodePtr);
DLLEXPORT int xml6_node_lock(xmlNodePtr);
DLLEXPORT int xml6_node_unlock(xmlNodePtr);

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr);
DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr, int blank);
DLLEXPORT xmlNodePtr xml6_node_last_child(xmlNodePtr, int blank);
DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr, int);
DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr, int);
DLLEXPORT void xml6_node_set_doc(xmlNodePtr, xmlDocPtr);
DLLEXPORT void xml6_node_set_ns(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_content(xmlNodePtr, xmlChar*);
DLLEXPORT int xml6_node_is_htmlish(xmlNodePtr);
DLLEXPORT xmlChar* xml6_node_to_buf(xmlNodePtr, int opts, size_t* len, char* enc);
DLLEXPORT xmlChar* xml6_node_to_str_C14N(xmlNodePtr, int comments, xmlC14NMode, xmlChar** inc_prefix_list, xmlNodeSetPtr nodelist);
DLLEXPORT int xml6_node_get_size(int type);

#endif /* __XML6_NODE_H */
