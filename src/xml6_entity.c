#include "xml6.h"
#include "xml6_entity.h"
#include <string.h>
#include <assert.h>


DLLEXPORT xmlEntityPtr
xml6_entity_create(const xmlChar *name, int type,
                   const xmlChar *ExternalID, const xmlChar *SystemID,
                   const xmlChar *content) {
    xmlEntityPtr rv;

    rv = (xmlEntityPtr) xmlMalloc(sizeof(xmlEntity));
    if (rv == NULL) {
        xml6_warn("xml6_entity_create: malloc failed");
	return(NULL);
    }
    memset(rv, 0, sizeof(xmlEntity));
    rv->type = XML_ENTITY_DECL;
    rv->checked = 0;

    /*
     * fill the structure.
     */
    rv->etype = (xmlEntityType) type;
    rv->name = xmlStrdup(name);
    if (ExternalID != NULL)
        rv->ExternalID = xmlStrdup(ExternalID);
    if (SystemID != NULL)
        rv->SystemID = xmlStrdup(SystemID);

    if (content != NULL) {
        rv->length = xmlStrlen(content);
        rv->content = xmlStrndup(content, rv->length);
     } else {
        rv->length = 0;
        rv->content = NULL;
    }

    rv->URI = NULL;
    rv->orig = NULL;
    rv->owner = 0;

    return(rv);
}
