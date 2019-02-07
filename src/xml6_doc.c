#include "xml6.h"
#include "xml6_doc.h"
#include <string.h>

DLLEXPORT void xml6_doc_set_encoding(xmlDocPtr self, char *encoding) {
  int charset = XML_CHAR_ENCODING_ERROR;

  if (self == NULL) xml6_fail("unable to update null document");

  if ( self->encoding != NULL ) {
    xmlFree( (xmlChar*) self->encoding );
  }

  if (encoding != NULL && strlen(encoding)) {
    self->encoding = xmlStrdup( (const xmlChar *)encoding );
    charset = (int)xmlParseCharEncoding( (const char*)self->encoding );
    if ( charset <= 0 ) {
            charset = XML_CHAR_ENCODING_ERROR;
    }
  } else {
    self->encoding = NULL;
    charset = XML_CHAR_ENCODING_UTF8;
  }
}

DLLEXPORT void xml6_doc_set_intSubset(xmlDocPtr self, xmlDtdPtr dtd) {
  xmlDtdPtr old_dtd;

  if (self == NULL) xml6_fail("unable to update null document");

  old_dtd = self->intSubset;
  if (old_dtd == dtd) {
    return;
  }

  if (old_dtd != NULL) {
    xmlUnlinkNode((xmlNodePtr) old_dtd);
    xmlFreeDtd(old_dtd);
  }

  self->intSubset = dtd;
}

DLLEXPORT void xml6_doc_set_URI(xmlDocPtr self, char *URI) {
  if (self == NULL) xml6_fail("unable to update null document");
  if (self->URL) xmlFree((xmlChar*)self->URL);
  self->URL = URI ? xmlStrdup((const xmlChar*)URI) : NULL;
}

DLLEXPORT void xml6_doc_set_version(xmlDocPtr self, char *version) {
  if (self == NULL) xml6_fail("unable to update null document");
  if (self->URL) xmlFree((xmlChar*)self->URL);
  self->version = version ? xmlStrdup((const xmlChar*)version) : NULL;
}

