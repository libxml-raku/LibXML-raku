#include "xml6.h"
#include "xml6_gbl.h"
#include <stdarg.h>
#include <string.h>

DLLEXPORT void xml6_gbl_set_tag_expansion(int flag) {
    xmlSaveNoEmptyTags = flag;
}

union MsgArg {
    int    i;
    long   l;
    double d;
    char*  s;
    void*  p;
};

DLLEXPORT void xml6_gbl_message_func(
    void *ctx,
    char *fmt, ...) {
    xml6_gbl_MessageCallback callback = (xml6_gbl_MessageCallback) ctx;
    char* fmtp = fmt;
    union MsgArg argv[11];
    char argt[12];

    int argc = 0;
    va_list ap;
    va_start(ap, fmt);
    while (*fmtp && argc < 10) {
        if (*fmtp++ == '%') {
            char c = *fmtp++;
            argt[argc] = c;
            memset(&(argv[argc]), 0, sizeof(union MsgArg));
            switch (c) {
                case 's':              /* string */
                    argv[argc++].s = va_arg(ap, char *);
                    break;
                case 'd':              /* int */
                    argv[argc++].i = va_arg(ap, int);
                    break;
                case 'f':              /* float */
                    argv[argc++].d = va_arg(ap, double);
                    break;
                case 'l':
                    c = *fmtp++;
                    c == 'd'
                        ? argv[argc++].l = va_arg(ap, long)
                        : fprintf(stderr, "ignoring '%%%lc' printf directive\n", c);
                    break;
                case '%':
                    fmtp++;
                    break;
                default:
                    c
                    ? fprintf(stderr, "ignoring '%%%c' printf directive\n", c)
                    : fprintf(stderr, "ignoring trailing '%%'\n");
            }
        }
    }
    argt[argc] = 0;
    (*callback)(fmt, argt, argv);
}
