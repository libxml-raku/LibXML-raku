#ifndef __XML6_GBL_H
#define __XML6_GBL_H

#include <libxml/globals.h>

DLLEXPORT void xml6_gbl_set_tag_expansion(int);

typedef void (*xml6_gbl_MessageCallback) (const char *msg,
                                          const char *argt,
                                          ...);

DLLEXPORT  void xml6_gbl_message_func(void *ctx,char *fmt, ...);

#endif /* __XML6_GBL_H */
