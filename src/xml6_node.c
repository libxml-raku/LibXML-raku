#include "xml6.h"
#include "xml6_node.h"

DLLEXPORT void xml6_node_set_doc(xmlNodePtr self, xmlDocPtr doc) {
  if (self == NULL) xml6_fail("unable to update null node");

  self->doc = doc;
}

DLLEXPORT void xml6_node_set_ns(xmlNodePtr self, xmlNsPtr ns) {
  if (self == NULL) xml6_fail("unable to update null node");

  self->ns = ns;
}

