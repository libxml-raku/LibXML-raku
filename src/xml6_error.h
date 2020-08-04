#ifndef __XML6_ERROR_H
#define __XML6_ERROR_H

#include <libxml/xmlerror.h>

DLLEXPORT xmlChar*
xml6_error_context_and_column( xmlErrorPtr, unsigned int*);

#endif /* __XML6_ERROR_H */
