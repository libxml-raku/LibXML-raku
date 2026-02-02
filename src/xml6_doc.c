#include "xml6.h"
#include "xml6_doc.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

DLLEXPORT void xml6_doc_set_encoding(xmlDocPtr self, char *encoding) {
    assert(self != NULL);

    if ( self->encoding != NULL ) {
        xmlFree( (xmlChar*) self->encoding );
    }

    if (encoding != NULL && strlen(encoding)) {
        self->encoding = xmlStrdup( (const xmlChar*) encoding );
    } else {
        self->encoding = NULL;
    }
}

DLLEXPORT void xml6_doc_set_URI(xmlDocPtr self, char *URI) {
    assert(self != NULL);
    if (self->URL) xmlFree((xmlChar*) self->URL);
    self->URL = URI ? xmlStrdup((const xmlChar*) URI) : NULL;
}

DLLEXPORT void xml6_doc_set_version(xmlDocPtr self, char *version) {
    assert(self != NULL);
    if (self->version) xmlFree((xmlChar*) self->version);
    self->version = version ? xmlStrdup((const xmlChar*) version) : NULL;
}

DLLEXPORT int
xml6_doc_set_doc_properties(xmlDocPtr self, int mask) {
    assert(self != NULL);
    self->properties |= mask;
    return self->properties;
}

DLLEXPORT int
xml6_doc_set_flags(xmlDocPtr self, int flags) {
    assert(self != NULL);
    assert(self->_private != NULL);
    return xml6_ref_set_flags( self->_private, flags);
}

DLLEXPORT int
xml6_doc_get_flags(xmlDocPtr self) {
    assert(self != NULL);
    assert(self->_private != NULL);
    return xml6_ref_get_flags( self->_private);
}

