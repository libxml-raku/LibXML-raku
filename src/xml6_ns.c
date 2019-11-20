#include "xml6.h"
#include "xml6_ns.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr self) {
    xmlNsPtr new = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));

    assert(self != NULL);
    assert(new != NULL);

    memset(new, 0, sizeof(xmlNs));
    new->type = self->type;

    if (self->href != NULL)
        new->href = xmlStrdup(self->href);
    if (self->prefix != NULL)
        new->prefix = xmlStrdup(self->prefix);
    return new;
}

DLLEXPORT xmlChar* xml6_ns_unique_key(xmlNsPtr self) {
    xmlChar *rv = NULL;

    assert(self != NULL);

    if (self->prefix != NULL) rv = xmlStrdup(self->prefix);
    rv = xmlStrcat(rv, (const xmlChar *) "|");
    if (self->href != NULL) rv = xmlStrcat(rv, self->href);
    return rv;
}
