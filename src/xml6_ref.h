#ifndef __XML6_REF_H
#define __XML6_REF_H

#include "xml6.h"
#include <libxml/parser.h>

#define XML6_REF_MAGIC 2020437046 // 'xml6', little endian

DLLEXPORT void xml6_ref_add(void**);
DLLEXPORT int xml6_ref_remove(void**, const char*, void*);
DLLEXPORT void xml6_ref_set_fail(void*, xmlChar*);
DLLEXPORT xmlChar* xml6_ref_get_fail(void*);

#define fail(self, msg) { self && self->_private ? xml6_ref_set_fail(self->_private, (xmlChar*)msg) : xml6_warn(msg); return NULL;}
#define fail_i(self, msg) {self && self->_private ? xml6_ref_set_fail(self->_private, (xmlChar*)msg) : xml6_warn(msg); return -1;}

#endif /* __XML6_REF_H */
