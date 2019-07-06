#ifndef __XML6_NODESET_H
#define __XML6_NODESET_H

#include "libxml/xpath.h"

DLLEXPORT xmlNodeSetPtr xml6_nodeset_resize(xmlNodeSetPtr, int nodeMax);
DLLEXPORT xmlNodeSetPtr xml6_nodeset_from_nodelist(xmlNodePtr, int keep_blanks);

#endif /* __XML6_NODESET_H */
