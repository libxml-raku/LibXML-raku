#ifndef __XML6_NODE_H
#define __XML6_NODE_H

#include <libxml/parser.h>

struct _xml6NodeProxy {
  int ref_count;
};

typedef struct _xml6NodeProxy xml6NodeProxy;
typedef xml6NodeProxy *xml6NodeProxyPtr;

DLLEXPORT void xml6_node_add_reference(xmlNodePtr);
DLLEXPORT void xml6_node_remove_reference(xmlNodePtr);
DLLEXPORT int xml6_node_is_referenced(xmlNodePtr);

DLLEXPORT void xml6_node_set_doc(xmlNodePtr, xmlDocPtr);
DLLEXPORT void xml6_node_set_ns(xmlNodePtr, xmlNsPtr);
DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr, xmlNsPtr);

#endif /* __XML6_NODE_H */
