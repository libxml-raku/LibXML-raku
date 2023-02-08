#ifndef __XML6_GBL_H
#define __XML6_GBL_H

#include <libxml/globals.h>

DLLEXPORT void xml6_gbl_init(void);

DLLEXPORT void* xml6_gbl_get_external_entity_loader(void);
DLLEXPORT void xml6_gbl_set_external_entity_loader(void *);
DLLEXPORT int xml6_gbl_set_external_entity_loader_net(int);

DLLEXPORT int xml6_gbl_os_thread_get_tag_expansion(void);
DLLEXPORT void xml6_gbl_os_thread_set_tag_expansion(int);

DLLEXPORT int xml6_gbl_os_thread_get_keep_blanks(void);
DLLEXPORT void xml6_gbl_os_thread_set_keep_blanks(int flag);

DLLEXPORT void xml6_gbl_os_thread_xml_free(void*);

DLLEXPORT xmlError* xml6_gbl_os_thread_get_last_error(void);

DLLEXPORT xmlSAXLocator xml6_gbl_os_thread_get_default_sax_locator(void);

typedef void (*xml6_gbl_MessageCallback) (const char *msg,
                                          const char *argt,
                                          ...);

DLLEXPORT void xml6_gbl_set_os_thread_generic_error_handler(xml6_gbl_MessageCallback, void (*route)(void*, xmlGenericErrorFunc));

DLLEXPORT void* xml6_gbl_save_error_handlers(void);
DLLEXPORT void xml6_gbl_restore_error_handlers(void*);

DLLEXPORT const xmlChar* xml6_gbl_dict(xmlChar*);
DLLEXPORT const xmlChar* xml6_gbl_dict_dup(const xmlChar* word);
DLLEXPORT int xml6_gbl_dict_size(void);

#endif /* __XML6_GBL_H */
