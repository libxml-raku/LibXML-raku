#include "xml6.h"
#include "xml6_doc.h"
#include <string.h>

DLLEXPORT void xml6_doc_set_encoding(xmlDocPtr self, char *encoding) {
    if (self == NULL) xml6_fail("unable to update null document");

    if ( self->encoding != NULL ) {
        xmlFree( (xmlChar*) self->encoding );
    }

    if (encoding != NULL && strlen(encoding)) {
        self->encoding = xmlStrdup( (const xmlChar *) encoding );
    } else {
        self->encoding = NULL;
    }
}

DLLEXPORT void xml6_doc_set_URI(xmlDocPtr self, char *URI) {
    if (self == NULL) xml6_fail("unable to update null document");
    if (self->URL) xmlFree((xmlChar*) self->URL);
    self->URL = URI ? xmlStrdup((const xmlChar*) URI) : NULL;
}

DLLEXPORT void xml6_doc_set_version(xmlDocPtr self, char *version) {
    if (self == NULL) xml6_fail("unable to update null document");
    if (self->version) xmlFree((xmlChar*) self->version);
    self->version = version ? xmlStrdup((const xmlChar*) version) : NULL;
}

DLLEXPORT void xml6_doc_set_dict(xmlDocPtr self, xmlDictPtr dict) {
    if (self == NULL) xml6_fail("unable to update null document");
    if (self->dict) {
        // todo: is it valid/safe to replace an existing doc dictionary?
        xml6_warn("discarding an existing document dictionary");
        xmlDictFree(self->dict);
    }
    self->dict = dict;
}

