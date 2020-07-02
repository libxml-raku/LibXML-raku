#ifndef __XML6_REF_H
#define __XML6_REF_H

#include "xml6.h"
#include <libxml/parser.h>

#define XML6_REF_MAGIC 2020437046 // 'xml6', little endian
#define XML6_FAIL(self, msg) { self && self->_private ? xml6_ref_set_fail(self->_private, (xmlChar*)msg) : xml6_warn(msg); return NULL;}
#define XML6_FAIL_i(self, msg) {self && self->_private ? xml6_ref_set_fail(self->_private, (xmlChar*)msg) : xml6_warn(msg); return -1;}

DLLEXPORT void xml6_ref_init(void);
DLLEXPORT void xml6_ref_add(void**);
DLLEXPORT int xml6_ref_remove(void**, const char*, void*);
DLLEXPORT void xml6_ref_set_fail(void*, xmlChar*);
DLLEXPORT xmlChar* xml6_ref_get_fail(void*);
DLLEXPORT int xml6_ref_set_flags(void*, int);
DLLEXPORT int xml6_ref_get_flags(void*);
DLLEXPORT int xml6_ref_lock(void*);
DLLEXPORT int xml6_ref_unlock(void*);
DLLEXPORT void* xml6_ref_freed();
DLLEXPORT int xml6_ref_count(void);

#endif /* __XML6_REF_H */
