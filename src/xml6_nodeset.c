#include "xml6.h"
#include "xml6_node.h"
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

static xmlNodeSetPtr resize_nodeset(xmlNodeSetPtr rv, int nodeMax) {
    xmlNodePtr *temp;
    int size;

    if (nodeMax < 10)
        nodeMax = 10;

    size = nodeMax * sizeof(xmlNodePtr);

    if (rv->nodeTab != NULL) {
        temp = (xmlNodePtr *) xmlRealloc(rv->nodeTab, size);
    }
    else {
        temp = (xmlNodePtr *) xmlMalloc(size);
    }

    assert(temp != NULL);

    rv->nodeMax = nodeMax;
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

DLLEXPORT xmlNodeSetPtr xml6_nodeset_from_nodelist(xmlNodePtr elem, int keep_blanks) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    int i = 0;
    assert(rv != NULL);
    while (elem != NULL) {
        if (i >= rv->nodeMax) {
            resize_nodeset(rv, rv->nodeMax * 2);
        }

        rv->nodeTab[i++] = elem;
        rv->nodeNr++;
        elem = xml6_node_next(elem, keep_blanks);
    }

    return rv;
}
