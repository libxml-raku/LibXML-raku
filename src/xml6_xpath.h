#ifndef __XML6_XPATH_H
#define __XML6_XPATH_H

#include <libxml/xpath.h>

#include "xml6.h"

DLLEXPORT void xml6_xpath_object_add_reference(xmlXPathObjectPtr);
DLLEXPORT int xml6_xpath_object_is_referenced(xmlXPathObjectPtr);
DLLEXPORT int xml6_xpath_object_remove_reference(xmlXPathObjectPtr);
DLLEXPORT xmlNodePtr xml6_xpath_ctxt_set_node(xmlXPathContextPtr, xmlNodePtr node);

#endif /* __XML6_XPATH_H */
