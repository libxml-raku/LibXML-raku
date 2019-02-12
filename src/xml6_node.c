#include "xml6.h"
#include "xml6_node.h"

DLLEXPORT void xml6_node_add_reference(xmlNodePtr self) {
  xml6NodeProxyPtr proxy;
  if ( self->_private == NULL ) {
    proxy = (xml6NodeProxyPtr)xmlMalloc(sizeof(struct _xml6NodeProxy));
    self->_private = (void*) proxy;
  }
  else {
    proxy = (xml6NodeProxyPtr) self->_private;
  }
  proxy->ref_count++;
}

DLLEXPORT int xml6_node_is_referenced(xmlNodePtr self) {

  xmlNodePtr cld;
  if (self->_private != NULL ) {
    return 1;
  }

  // Look for child references
  cld = self->children;
  while ( cld ) {
    if (xml6_node_is_referenced( cld )) {
      return 1;
    }
    cld = cld->next;
  }

  return 0;
}

DLLEXPORT void xml6_node_remove_reference(xmlNodePtr self) {
  if ( self->_private == NULL ) {
    xml6_warn("node was not referenced");
  }
  else {
    xml6NodeProxyPtr proxy = (xml6NodeProxyPtr) self->_private;
    if (proxy->ref_count <= 0 || proxy->ref_count >= 65536) {
      xml6_warn("node has unexpected ref_count value");
    }
    else {
      if (proxy->ref_count == 1) {
        self->_private = NULL;
        xmlFree((void*) proxy);
      }
      else {
        proxy->ref_count--;
      }
    }
  }
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

