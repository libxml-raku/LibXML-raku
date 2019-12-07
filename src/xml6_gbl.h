#ifndef __XML6_GBL_H
#define __XML6_GBL_H

#include <libxml/globals.h>

DLLEXPORT void xml6_gbl_init_external_entity_loader(void);
DLLEXPORT int xml6_gbl_set_external_entity_loader(int net);
DLLEXPORT void xml6_gbl_set_tag_expansion(int);

typedef void (*xml6_gbl_MessageCallback) (const char *msg,
                                          const char *argt,
                                          ...);

DLLEXPORT  void xml6_gbl_message_func(void *ctx,char *fmt, ...);

DLLEXPORT void* xml6_gbl_save_error_handlers(void);
DLLEXPORT void xml6_gbl_restore_error_handlers(void*);

#endif /* __XML6_GBL_H */
