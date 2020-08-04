#ifndef __XML6_ENTITY_H
#define __XML6_ENTITY_H

#include <libxml/entities.h>

DLLEXPORT xmlEntityPtr
xml6_entity_create(const xmlChar *name, int type,
                   const xmlChar *ExternalID, const xmlChar *SystemID,
                   const xmlChar *content);

#endif /* __XML6_ENTITY_H */
