#include "xml6.h"
#include "xml6_doc.h"

// adapted from 
DLLEXPORT void xml6_doc_set_int_subset(xmlDocPtr doc, xmlDtdPtr dtd) {
  xmlDtdPtr old_dtd;

  if (doc == NULL) xml6_fail("unable to update null document");

  old_dtd = doc->intSubset;
  if (old_dtd == dtd) {
    return;
  }

  if (old_dtd != NULL) {
    xmlUnlinkNode((xmlNodePtr) old_dtd);

    if (old_dtd == NULL) {
      xmlFreeDtd(old_dtd);
    }
  }

  doc->intSubset = dtd;
}

DLLEXPORT void xml6_doc_set_uri(xmlDocPtr doc, char *uri) {
  if (doc == NULL) xml6_fail("unable to update null document");
  if (doc->URL) xmlFree((xmlChar*)doc->URL);
  doc->URL = uri ? xmlStrdup((const xmlChar*)uri) : NULL;
}
