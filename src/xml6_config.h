#ifndef __XML6_CONFIG_H
#define __XML6_CONFIG_H

#include <libxml/xmlversion.h>

DLLEXPORT int   xml6_config_have_libxml_reader(void);
DLLEXPORT int   xml6_config_have_libxml_writer(void);
DLLEXPORT int   xml6_config_have_threads(void);
DLLEXPORT int   xml6_config_have_compression(void);
DLLEXPORT int   xml6_config_have_iconv(void);
DLLEXPORT char* xml6_config_version(void);

#endif /* __XML6_CONFIG_H */
