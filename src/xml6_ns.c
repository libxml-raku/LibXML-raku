#include "xml6.h"
#include "xml6_ns.h"
#include <string.h>

DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr self) {
  xmlNsPtr new = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));
  if (new == NULL) {
    xml6_warn("Error building namespace");
  }
  else {
    memset(new, 0, sizeof(xmlNs));
    new->type = XML_LOCAL_NAMESPACE;

    if (self->href != NULL)
      new->href = xmlStrdup(self->href);
    if (self->prefix != NULL)
      new->prefix = xmlStrdup(self->prefix);
  }
  return new;
}
