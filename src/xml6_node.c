#include "xml6.h"
#include "xml6_node.h"

// adapted from 
DLLEXPORT void xml6_node_set_doc(xmlNodePtr node, xmlDocPtr doc) {
  if (node == NULL) xml6_fail("unable to update null node");

  node->doc = doc;
}

