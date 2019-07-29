#include "xml6.h"
#include "xml6_gbl.h"
#include "libxml/xmlversion.h"

DLLEXPORT void xml6_gbl_set_tag_expansion(int flag) {
    xmlSaveNoEmptyTags = flag;
}

DLLEXPORT int xml6_gbl_have_libxml_reader(void) {
#ifdef LIBXML_READER_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_gbl_have_threads(void) {
#ifdef LIBXML_THREAD_ENABLED
    return 1;
#else
    return 0;
#endif
}

DLLEXPORT int xml6_gbl_have_compression(void) {
#ifdef LIBXML_ZLIB_ENABLED
    return 1;
#else
    return 0;
#endif
}

