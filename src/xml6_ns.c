#include "xml6.h"
#include "xml6_ns.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr self) {
    xmlNsPtr new = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));
    assert(new != NULL);
    memset(new, 0, sizeof(xmlNs));
    new->type = self->type;

    if (self->href != NULL)
        new->href = xmlStrdup(self->href);
    if (self->prefix != NULL)
        new->prefix = xmlStrdup(self->prefix);
    return new;
}
