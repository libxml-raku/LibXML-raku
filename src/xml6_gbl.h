#ifndef __XML6_GBL_H
#define __XML6_GBL_H

#include <libxml/globals.h>

DLLEXPORT int xml6_gbl_set_external_entity_loader(int net);
DLLEXPORT void xml6_gbl_set_tag_expansion(int);

typedef void (*xml6_gbl_MessageCallback) (const char *msg,
                                          const char *argt,
                                          ...);

DLLEXPORT void xml6_gbl_set_generic_error_handler(xml6_gbl_MessageCallback, void (*route)(void*, xmlGenericErrorFunc));

DLLEXPORT void* xml6_gbl_save_error_handlers(void);
DLLEXPORT void xml6_gbl_restore_error_handlers(void*);

#endif /* __XML6_GBL_H */
