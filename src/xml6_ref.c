#include "xml6.h"
#include "xml6_ref.h"
#include "libxml/threads.h"
#include <string.h>

struct _xml6Ref {
    int magic;     /* for verification */
    int ref_count;
    xmlMutexPtr mutex;
    xmlChar *fail;
};

typedef struct _xml6Ref xml6Ref;
typedef xml6Ref *xml6RefPtr;

static xml6RefPtr
_ref_new(void) {
    xml6RefPtr ref = (xml6RefPtr)xmlMalloc(sizeof(struct _xml6Ref));
    memset(ref, 0, sizeof(struct _xml6Ref));
    ref->magic = XML6_REF_MAGIC;
    ref->mutex = xmlNewMutex();
    ref->ref_count = 1;
    return ref;
}

static xmlMutexPtr _mutex = NULL;
DLLEXPORT void
xml6_ref_init(void) {
    if (_mutex == NULL) {
        _mutex = xmlNewMutex();
    }
}

DLLEXPORT void
xml6_ref_add(void** self_ptr) {
    xml6RefPtr self;
    int init = 0;

    if ( *self_ptr == NULL ) {

        if (_mutex == NULL) {
            xml6_warn("xml6_ref_init() wasn't called");
            xml6_ref_init();
        }

        xmlMutexLock(_mutex);
        if ( *self_ptr == NULL ) {
            self = _ref_new();
            *self_ptr = (void*) self;
            init = 1;
        }
        xmlMutexUnlock(_mutex);
    }

    if (!init) {
        self = (xml6RefPtr) *self_ptr;

        if (self->magic != XML6_REF_MAGIC) {
            char msg[80];
            sprintf(msg, "%p is not owned by us, or is corrupted", self);
            xml6_warn(msg);
        }
        else {
            xmlMutexLock(self->mutex);
            self->ref_count++;
            xmlMutexUnlock(self->mutex);
        }
    }
}

DLLEXPORT int
xml6_ref_remove(void** self_ptr, const char* what, void* where) {
    char msg[120];
    int released = 0;

    if (*self_ptr == NULL) {
        sprintf(msg, "%s %p was not referenced", what, where);
        xml6_warn(msg);
        released = 1;
    }
    else {
        xml6RefPtr self = (xml6RefPtr) *self_ptr;
        if (self->magic != XML6_REF_MAGIC) {
            sprintf(msg, "%s %p is not owned by us, or is corrupted", what, where);
            xml6_warn(msg);
        }
        else {
            xmlMutexPtr mutex = self->mutex;
            if (mutex != NULL) xmlMutexLock(mutex);

            if (self->ref_count <= 0 || self->ref_count >= 65536) {
                sprintf(msg, "%s %p has unexpected ref_count value: %ld", what, where, self->ref_count);
                xml6_warn(msg);
            }
            else {
                if (self->ref_count == 1) {
                    if (self->fail != NULL) {
                        snprintf(msg, sizeof(msg), "uncaught failure on %s %p destruction: %s", what, where, self->fail);
                        xml6_warn(msg);
                        xmlFree(self->fail);
                    }
                    *self_ptr = NULL;
                    xmlFree((void*) self);
                    self = NULL;
                    released = 1;
                }
                else {
                    self->ref_count--;
                }
            }
            if (mutex != NULL) {
                xmlMutexUnlock(mutex);
                if (self == NULL) {
                    // mutex owner has been destroyed.
                    xmlFreeMutex(mutex);
                    mutex = NULL;
                }
            }
        }
    }
    return released;
}

DLLEXPORT void
xml6_ref_set_fail(void* _self, xmlChar* fail) {
    xml6RefPtr self = (xml6RefPtr) _self;

    if (self != NULL && self->magic == XML6_REF_MAGIC) {
        xmlMutexLock(self->mutex);
        if (self->fail) xmlFree(self->fail);
        self->fail = xmlStrdup(fail);
        xmlMutexUnlock(self->mutex);
    }
    else if (fail != NULL) {
        // nowhere to attach the message
        xml6_warn(fail);
    }
}

DLLEXPORT xmlChar*
xml6_ref_get_fail(void* _self) {
  xml6RefPtr self = (xml6RefPtr) _self;
  xmlChar* fail = NULL;

  if (self != NULL && self->magic == XML6_REF_MAGIC) {
      xmlMutexLock(self->mutex);
      fail = self->fail;
      self->fail = NULL;
      xmlMutexUnlock(self->mutex);
  }
  return fail;
}

DLLEXPORT int
xml6_ref_lock(void* _self) {
    xml6RefPtr self = (xml6RefPtr) _self;
    if (self && self->magic == XML6_REF_MAGIC && self->mutex) {
        xmlMutexLock(self->mutex);
        return 1;
    }
    return 0;
}

DLLEXPORT int
xml6_ref_unlock(void* _self) {
    xml6RefPtr self = (xml6RefPtr) _self;
    if (self && self->magic == XML6_REF_MAGIC && self->mutex) {
        xmlMutexUnlock(self->mutex);
        return 1;
    }
    return 0;
}
