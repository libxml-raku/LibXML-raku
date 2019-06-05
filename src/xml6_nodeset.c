#include "xml6.h"
#include "xml6_nodeset.h"
#include <assert.h>
#include "libxml/xpathInternals.h"

DLLEXPORT xmlNodeSetPtr xml6_nodeset_copy(xmlNodeSetPtr self) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    assert(rv != NULL);

    if (self != NULL) {
        int i;

        for (i = 0; i < self->nodeNr; i++) {
            xmlXPathNodeSetAdd(rv, self->nodeTab[i]);
        }
        assert(rv->nodeNr == self->nodeNr);
    }

    return rv;
}
