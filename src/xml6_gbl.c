#include "xml6.h"
#include "xml6_gbl.h"
#include <stdarg.h>
#include <string.h>

DLLEXPORT void xml6_gbl_set_tag_expansion(int flag) {
    xmlSaveNoEmptyTags = flag;
}

union MsgArg {
    double f;
    int    d;
    long   l;
    char*  s;
    void*  p;
};

DLLEXPORT void xml6_gbl_message_func(
    void *ctx,         // actually our callback...
    char *fmt, ...) {  // incoming vararg message
    xml6_gbl_MessageCallback callback = (xml6_gbl_MessageCallback) ctx;
    char* fmtp = fmt;
    int argc = 0;
    va_list ap;
    char argt[12];          // argument types: s=string, d=int, f=double, l=long
    union MsgArg argv[11];  // argument values

    va_start(ap, fmt);
    // Consume variable arguments; marshal into argt[] and argv[].
    // Note: this is a limited parse of printf directives; it does just enough
    // to handle those that are used by libxml2, i.e.: %s, %d, %f, %lf, %ld, %%
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
                    argv[argc++].d = va_arg(ap, int);
                    break;
                case 'f':              /* float (upgraded by va_arg() to double) */
                    argv[argc++].f = va_arg(ap, double);
                    break;
                case 'l':
                    c = *fmtp++;
                    switch (c) {
                        case 'd':      /* long */
                            argv[argc++].l = va_arg(ap, long);
                            break;
                        case 'f':      /* double */
                            argt[argc] = 'f';
                            argv[argc++].f = va_arg(ap, double);
                            break;
                        default:
                            fprintf(stderr, "ignoring '%%l%c' printf directive\n", c);
                    }
                    break;
                case '%':
                    fmtp++;
                    break;
                default:
                    c
                    ? fprintf(stderr, "ignoring '%%%c' in format string\n", c)
                    : fprintf(stderr, "ignoring trailing '%%' in format string\n");
            }
        }
    }
    argt[argc] = 0; // null terminate

    // invoke the error handling callback; pass arguments
    (*callback)(fmt, argt, argv);
}
