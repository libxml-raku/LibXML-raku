#include "xml6.h"
#include "xml6_xpath.h"
#include "xml6_ref.h"

DLLEXPORT void
xml6_xpath_object_add_reference(xmlXPathObjectPtr self) {
    xml6_ref_add( &(self->user2) );
}

DLLEXPORT int
xml6_xpath_object_remove_reference(xmlXPathObjectPtr self) {
    return xml6_ref_remove( &(self->user2), "xpath object", (void*) self );
}

DLLEXPORT xmlNodePtr
xml6_xpath_ctxt_set_node(xmlXPathContextPtr ctxt, xmlNodePtr node) {
    if (node != NULL) {
        if (ctxt->doc != node->doc)
            fail(node, "changing XPathContext between documents is not supported");
    }
    else {
        node = (xmlNodePtr) ctxt->doc;
    }

    ctxt->node = node;

    return node;
}
