#include "xml6_reader.h"

DLLEXPORT int
xml6_reader_next_sibling(xmlTextReaderPtr self) {
    int rv = xmlTextReaderNextSibling(self);
    if (rv == -1) {
        int depth = xmlTextReaderDepth(self);
	rv = xmlTextReaderRead(self);
        while (rv == 1 && xmlTextReaderDepth(self) > depth) {
	    rv = xmlTextReaderNext(self);
        }
        if (rv == 1) {
	    if (xmlTextReaderDepth(self) != depth) {
                rv = 0;
	    } else if (xmlTextReaderNodeType(self) == XML_READER_TYPE_END_ELEMENT) {
                rv = xmlTextReaderRead(self);
	    }
        }
    }
    return rv;
}

static int match_element(xmlTextReaderPtr self, char *name, char *URI) {
    return ((!URI && !name)
            || (!URI && xmlStrcmp((const xmlChar*)name, xmlTextReaderConstName(self) ) == 0 )
            || (URI && xmlStrcmp((const xmlChar*)URI, xmlTextReaderConstNamespaceUri(self)) == 0
                && (!name || xmlStrcmp((const xmlChar*)name, xmlTextReaderConstLocalName(self)) == 0)));
}

DLLEXPORT int
xml6_reader_next_element(xmlTextReaderPtr self, char *name, char *URI) {
    int rv;

    do {
        rv = xmlTextReaderRead(self);
        if (match_element(self, name, URI)) {
	    break;
        }
    } while (rv == 1);

    return rv;
 }
