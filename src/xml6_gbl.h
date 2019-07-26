#ifndef __XML6_GBL_H
#define __XML6_GBL_H

#include <libxml/globals.h>

DLLEXPORT void xml6_gbl_set_tag_expansion(int);
DLLEXPORT int  xml6_gbl_have_libxml_reader(void);
DLLEXPORT int  xml6_gbl_have_threads(void);

#endif /* __XML6_GBL_H */
