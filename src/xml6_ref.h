#ifndef __XML6_REF_H
#define __XML6_REF_H

#include <libxml/parser.h>

#define XML6_REF_MAGIC 2020437046 // 'xml6', little endian

DLLEXPORT void xml6_ref_add(void**);
DLLEXPORT int xml6_ref_remove(void**, const char*, void*);
DLLEXPORT void xml6_ref_set_msg(void*, xmlChar*);
DLLEXPORT xmlChar* xml6_ref_get_msg(void*);

#endif /* __XML6_REF_H */
