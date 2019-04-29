#include "xml6.h"
#include "xml6_gbl.h"

DLLEXPORT void xml6_gbl_set_tag_expansion(int flag) {
    xmlSaveNoEmptyTags = flag;
}
