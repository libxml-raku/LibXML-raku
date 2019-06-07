#include "xml6.h"
#include "xml6_nodeset.h"
#include <assert.h>
#include <string.h>
#include "libxml/xpath.h"
#include "libxml/xpathInternals.h"

static xmlNsPtr dup_ns(xmlNsPtr ns) {
    xmlNsPtr dup = (xmlNsPtr) xmlMalloc(sizeof(xmlNs));
    assert(dup != NULL);
    memset(dup, 0, sizeof(xmlNs));
    dup->type = XML_NAMESPACE_DECL;
    if (ns->href != NULL)
        dup->href = xmlStrdup(ns->href);
    if (ns->prefix != NULL)
        dup->prefix = xmlStrdup(ns->prefix);
    dup->next = ns->next;
    return dup;
}

xmlNodeSetPtr resize_nodeset(xmlNodeSetPtr rv, int nodeNr) {
    xmlNodePtr *temp = (xmlNodePtr *) xmlRealloc(
        rv->nodeTab,
        nodeNr * sizeof(xmlNodePtr));
    assert(temp != NULL);
    rv->nodeMax = nodeNr;
    rv->nodeTab = temp;
    return rv;
}

DLLEXPORT xmlNodeSetPtr xml6_nodeset_copy(xmlNodeSetPtr self) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    int i;

    assert(rv != NULL);

    if (self != NULL) {

        if (self->nodeNr > rv->nodeMax) {
            resize_nodeset(rv, self->nodeNr);
        }

        for (i = 0; i < self->nodeNr; i++) {
            xmlNodePtr elem = self->nodeTab[i];
            if (elem->type == XML_NAMESPACE_DECL) {
                elem = (xmlNodePtr) dup_ns( (xmlNsPtr) elem );
            }
            rv->nodeTab[i] = elem;
            rv->nodeNr++;
        }
    }

    return rv;
}
