#include "xml6.h"
#include "xml6_node.h"
#include "xml6_nodeset.h"
#include <assert.h>
#include "libxml/xpath.h"
#include "libxml/xpathInternals.h"

DLLEXPORT xmlNodeSetPtr xml6_nodeset_resize(xmlNodeSetPtr rv, int nodeMax) {
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

DLLEXPORT xmlNodeSetPtr xml6_nodeset_from_nodelist(xmlNodePtr elem, int keep_blanks) {
    xmlNodeSetPtr rv = xmlXPathNodeSetCreate(NULL);
    int i = 0;
    assert(rv != NULL);
    while (elem != NULL) {
        if (i >= rv->nodeMax) {
            xml6_nodeset_resize(rv, rv->nodeMax * 2);
        }

        rv->nodeTab[i++] = elem;
        elem = xml6_node_next(elem, keep_blanks);
    }
    rv->nodeNr = i;

    return rv;
}
