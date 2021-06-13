#include "xml6.h"
#include "xml6_enumeration.h"
#include <assert.h>
#include <string.h>

static void
_enumeration_dump(xmlEnumerationPtr self, xmlBufferPtr buf, int first) {
    if (first)
        xmlBufferWriteChar(buf, "(");

    xmlBufferWriteChar(buf, self->name);
    if (self->next == NULL)
	xmlBufferWriteChar(buf, ")");
    else {
	xmlBufferWriteChar(buf, "|");
	_enumeration_dump(self->next, buf, 0);
    }

}

DLLEXPORT xmlChar* xml6_enumeration_to_string(xmlEnumerationPtr self) {
    xmlBufferPtr buf;
    xmlChar* rv;
    if (self == NULL) return NULL;
    buf = xmlBufferCreate();
    if (buf == NULL) return NULL;
    _enumeration_dump(self, buf, 1);
    rv = xmlBufferDetach(buf);
    xmlBufferFree(buf);
    return rv;
}

DLLEXPORT int
xml6_enumeration_accepts(xmlEnumerationPtr self, xmlChar* val) {
    if ((val == NULL) || (self == NULL))
        return 0;

    if (xmlStrcmp(self->name, val) == 0) {
        return 1;
    }
    if (self->next == NULL) {
	return 0;
    }

    return xml6_enumeration_accepts(self->next, val);
}
