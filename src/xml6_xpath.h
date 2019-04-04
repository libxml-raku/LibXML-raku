#ifndef __XML6_XPATH_H
#define __XML6_XPATH_H

#include <libxml/xpath.h>

#include "xml6.h"

DLLEXPORT void xml6_xpath_object_add_reference(xmlXPathObjectPtr);
DLLEXPORT int xml6_xpath_object_remove_reference(xmlXPathObjectPtr);

#endif /* __XML6_XPATH_H */
