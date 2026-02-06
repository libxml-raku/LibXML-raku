#include "xml6.h"
#include "xml6_config.h"
#include "libxml/xmlversion.h"

DLLEXPORT char* xml6_config_version(void) {
    return LIBXML_DOTTED_VERSION;
}
