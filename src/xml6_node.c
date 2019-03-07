#include "xml6.h"
#include "xml6_node.h"
#include <string.h>

DLLEXPORT void xml6_node_add_reference(xmlNodePtr self) {
  xml6NodeProxyPtr proxy;
  if ( self->_private == NULL ) {
    proxy = (xml6NodeProxyPtr)xmlMalloc(sizeof(struct _xml6NodeProxy));
    memset(proxy, 0, sizeof(struct _xml6NodeProxy));
    proxy->magic = XML_NODE_MAGIC;
    self->_private = (void*) proxy;
  }
  else {
    proxy = (xml6NodeProxyPtr) self->_private;
  }
  proxy->ref_count++;
}

DLLEXPORT int xml6_node_remove_reference(xmlNodePtr self) {
  int released = 0;
  char msg[80];

  if ( self->_private == NULL ) {
    xml6_warn("node was not referenced");
    released = 1;
  }
  else {
    xml6NodeProxyPtr proxy = (xml6NodeProxyPtr) self->_private;
    if (proxy->magic != XML_NODE_MAGIC) {
      sprintf(msg, "node %ld is not owned by us, or is corrupted", (long) self);
      xml6_warn(msg);
    }
    else {
      if (proxy->ref_count <= 0 || proxy->ref_count >= 65536) {

        sprintf(msg, "node %ld has unexpected ref_count value: %ld", (long) self, proxy->ref_count);
        xml6_warn(msg);
      }
      else {
        if (proxy->ref_count == 1) {
          self->_private = NULL;
          xmlFree((void*) proxy);
          released = 1;
        }
        else {
          proxy->ref_count--;
        }
      }
    }
  }
  return released;
}

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr node) {
  while (node && node->parent) {
    node = node->parent;
  }
  return node;
}

DLLEXPORT void xml6_node_set_doc(xmlNodePtr self, xmlDocPtr doc) {
  if (self == NULL) xml6_fail("unable to update null node");

  self->doc = doc;
}

DLLEXPORT void xml6_node_set_ns(xmlNodePtr self, xmlNsPtr ns) {
  if (self == NULL) xml6_fail("unable to update null node");

  self->ns = ns;
}

DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr self, xmlNsPtr ns) {
  if (self == NULL) xml6_fail("unable to update null node");

  self->nsDef = ns;
}

