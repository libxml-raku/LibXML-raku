#include "xml6.h"
#include "xml6_node.h"
#include "xml6_ref.h"

DLLEXPORT void xml6_node_add_reference(xmlNodePtr self) {
  xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_node_remove_reference(xmlNodePtr self) {
  return xml6_ref_remove( &(self->_private) );
}

DLLEXPORT xmlNodePtr xml6_node_find_root(xmlNodePtr node) {
  while (node && node->parent) {
    node = node->parent;
  }
  return node;
}

DLLEXPORT xmlNodePtr xml6_node_first_child(xmlNodePtr node, int keep_blanks) {
  node = node->children;
  if (keep_blanks == 0) {
    while (node && xmlIsBlankNode(node)) {
      node = node->next;
    }
  }

  return node;
}

DLLEXPORT xmlNodePtr xml6_node_next(xmlNodePtr node, int keep_blanks) {
  do {
    node = node->next;
  } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

  return node;
}

DLLEXPORT xmlNodePtr xml6_node_prev(xmlNodePtr node, int keep_blanks) {
  do {
    node = node->prev;
  } while (node != NULL && keep_blanks == 0 && xmlIsBlankNode(node));

  return node;
}

DLLEXPORT void xml6_node_set_doc(xmlNodePtr self, xmlDocPtr doc) {
  if (self == NULL) xml6_fail("unable to update null node");
  if (self->doc && self->doc != doc) xml6_warn("possible memory leak in setting node->doc");

  self->doc = doc;
}

DLLEXPORT void xml6_node_set_ns(xmlNodePtr self, xmlNsPtr ns) {
  if (self == NULL) xml6_fail("unable to update null node");
  if (self->ns && self->ns != ns) xml6_warn("possible memory leak in setting node->ns");

  self->ns = ns;
}

DLLEXPORT void xml6_node_set_nsDef(xmlNodePtr self, xmlNsPtr ns) {
  if (self == NULL) xml6_fail("unable to update null node");
  if (self->nsDef && self->nsDef != ns) xml6_warn("possible memory leak in setting node->nsDef");

  self->nsDef = ns;
}

DLLEXPORT void xml6_node_set_content(xmlNodePtr self, xmlChar* new_content) {
  if (self == NULL) xml6_fail("unable to update null node");
    if (self->content) xmlFree(self->content);
    self->content = new_content ? xmlStrdup((const xmlChar *) new_content) : NULL;
}
