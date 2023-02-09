#include "xml6.h"
#include "xml6_config.h"
#include "libxml/xmlversion.h"

DLLEXPORT int xml6_config_have_libxml_reader(void) {
#ifdef LIBXML_READER_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_config_have_libxml_writer(void) {
#ifdef LIBXML_WRITER_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_config_have_threads(void) {
#ifdef LIBXML_THREAD_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_config_have_compression(void) {
#ifdef LIBXML_ZLIB_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_config_have_iconv(void) {
#ifdef LIBXML_ICONV_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT char* xml6_config_version(void) {
    return LIBXML_DOTTED_VERSION;
}


