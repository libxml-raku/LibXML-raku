#include "xml6.h"
#include "xml6_ns.h"
#include "xml6_ref.h"
#include <string.h>
#include <assert.h>

DLLEXPORT void xml6_ns_add_reference(xmlNsPtr self) {
    assert(self != NULL);
    xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_ns_remove_reference(xmlNsPtr self) {
    return xml6_ref_remove( &(self->_private), "namespace", (void*) self);
}

DLLEXPORT xmlNsPtr xml6_ns_copy(xmlNsPtr self) {
    xmlNsPtr new = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));

    if (new == NULL) {
        xml6_fail("Error building namespace");
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
