#include "xml6.h"
#include "xml6_ref.h"
#include <string.h>

struct _xml6Ref {
  uint magic;     /* for verification */
  int ref_count;
  xmlChar *msg;
};

typedef struct _xml6Ref xml6Ref;
typedef xml6Ref *xml6RefPtr;

static xml6RefPtr
_ref_new(void) {
  xml6RefPtr ref = (xml6RefPtr)xmlMalloc(sizeof(struct _xml6Ref));
  memset(ref, 0, sizeof(struct _xml6Ref));
  ref->magic = XML6_REF_MAGIC;
  return ref;
}

DLLEXPORT void
xml6_ref_add(void** self_ptr) {
  xml6RefPtr self;
  if ( *self_ptr == NULL ) {
    self = _ref_new();
    *self_ptr = (void*) self;
  }
  else {
    self = (xml6RefPtr) *self_ptr;
  }

  if (self->magic != XML6_REF_MAGIC) {
    char msg[80];
    sprintf(msg, "node %ld is not owned by us, or is corrupted", (long) self);
    xml6_warn(msg);
  }
  else {
    self->ref_count++;
  }
}

DLLEXPORT int
xml6_ref_remove(void** self_ptr, const char* what, void* where) {
  char msg[80];
  int released = 0;
  if (*self_ptr == NULL) {
    sprintf(msg, "%s %ld was not referenced", what, (long) where);
    xml6_warn(msg);
    released = 1;
  }
  else {
    xml6RefPtr self = (xml6RefPtr) *self_ptr;
    if (self->magic != XML6_REF_MAGIC) {
      sprintf(msg, "%s %ld is not owned by us, or is corrupted", what, (long) where);
      xml6_warn(msg);
    }
    else {
      if (self->ref_count <= 0 || self->ref_count >= 65536) {

        sprintf(msg, "%s %ld has unexpected ref_count value: %ld", what, (long) where, (long) self->ref_count);
        xml6_warn(msg);
      }
      else {
        if (self->ref_count == 1) {
          if (self->msg != NULL) {
            char msg[120];
            sprintf(msg, "uncaught error on %s %ld: %s", what, (long) where, self->msg);
            xml6_warn(msg);
            xmlFree(self->msg);
          }
          *self_ptr = NULL;
          xmlFree((void*) self);
          released = 1;
        }
        else {
          self->ref_count--;
        }
      }
    }
  }
  return released;
}

DLLEXPORT void
xml6_ref_set_msg(void* _self, xmlChar* msg) {
  xml6RefPtr self = (xml6RefPtr) _self;
  if (self != NULL && self->magic == XML6_REF_MAGIC) {
    if (self->msg) xmlFree(self->msg);
    self->msg = xmlStrdup(msg);
  }
  else if (msg != NULL) {
    // nowhere to attach the message
    xml6_warn(msg);
  }
}

DLLEXPORT xmlChar*
xml6_ref_get_msg(void* _self) {
  xml6RefPtr self = (xml6RefPtr) _self;
  xmlChar* msg = NULL;
  if (self != NULL && self->magic == XML6_REF_MAGIC) {
     msg = self->msg;
     self->msg = NULL;
  }
  return msg;
}
