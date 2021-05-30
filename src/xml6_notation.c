#include "xml6.h"
#include "xml6_notation.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

DLLEXPORT xmlNotationPtr xml6_notation_copy(xmlNotationPtr self) {
    xmlNotationPtr new = (xmlNotationPtr) xmlMalloc(sizeof(xmlNotation));

    assert(self != NULL);
    assert(new != NULL);

    memset(new, 0, sizeof(xmlNotation));

    if (self->name != NULL)
        new->name = xmlStrdup(self->name);
    if (self->SystemID != NULL)
        new->SystemID = xmlStrdup(self->SystemID);
    if (self->PublicID != NULL)
        new->PublicID = xmlStrdup(self->PublicID);
    return new;
}

DLLEXPORT xmlChar* xml6_notation_unique_key(xmlNotationPtr self) {
    xmlChar *rv = NULL;

    assert(self != NULL);

    if (self->name != NULL) rv = xmlStrdup(self->name);
    rv = xmlStrcat(rv, (const xmlChar *) "|");
    if (self->PublicID != NULL) rv = xmlStrdup(self->PublicID);
    rv = xmlStrcat(rv, (const xmlChar *) "|");
    if (self->SystemID != NULL) rv = xmlStrcat(rv, self->SystemID);
    return rv;
}

DLLEXPORT xmlNotationPtr
xml6_notation_create(const xmlChar *name, const xmlChar *PublicID, const xmlChar *SystemID) {
    xmlNotationPtr self = (xmlNotationPtr) xmlMalloc(sizeof(xmlNotation));
    memset(self, 0, sizeof(xmlNotation));
    self->name = xmlStrdup(name);
    if (SystemID != NULL)
        self->SystemID = xmlStrdup(SystemID);
    if (PublicID != NULL)
        self->PublicID = xmlStrdup(PublicID);
    return self;
}

DLLEXPORT void
xml6_notation_free(xmlNotationPtr self) {
    if (self == NULL) return;
    if (self->name != NULL)
	xmlFree((xmlChar *) self->name);
    if (self->PublicID != NULL)
	xmlFree((xmlChar *) self->PublicID);
    if (self->SystemID != NULL)
	xmlFree((xmlChar *) self->SystemID);
    xmlFree(self);
}

