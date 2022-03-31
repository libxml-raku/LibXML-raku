#include "xml6.h"
#include "xml6_gbl.h"
#include <libxml/parser.h>
#include <libxml/xmlIO.h>
#include <stdarg.h>
#include <string.h>

static xmlExternalEntityLoader default_ext_entity_loader = NULL;

DLLEXPORT int xml6_gbl_set_external_entity_loader(int net) {
    int update = 0;
    if (default_ext_entity_loader == NULL) {
        default_ext_entity_loader = xmlGetExternalEntityLoader();
    }

    if (net) {
        update = xmlGetExternalEntityLoader() == xmlNoNetExternalEntityLoader;
        if (update) xmlSetExternalEntityLoader(default_ext_entity_loader);
    }
    else {
        update = xmlGetExternalEntityLoader() == default_ext_entity_loader;
        if (update) xmlSetExternalEntityLoader(xmlNoNetExternalEntityLoader);
    }

    return update;
}

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

static void _gbl_message_func(
    void* ctx,         // actually our callback...
    char* fmt, ...) {  // incoming vararg message
    xml6_gbl_MessageCallback callback = (xml6_gbl_MessageCallback) ctx;
    char* fmtp = fmt;
    int argc = 0;
    va_list ap;
    char argt[12];          // argument types: s=string, d=int, f=double, l=long
    union MsgArg argv[11];  // argument values

    va_start(ap, fmt);
    // Consume variable arguments; marshal into argt[] and argv[].
    // Note: this is a limited parse of printf directives; it does just enough
    // to handle those that are emitted by libxml2, i.e.: %s, %d, %f, %lf, %ld, %%
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
                            fprintf(stderr, "ignoring '%%l%c' in format string\n", c);
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

DLLEXPORT void xml6_gbl_set_generic_error_handler(xml6_gbl_MessageCallback callback,  void (*route)(void*, xmlGenericErrorFunc)) {
    /* we actually set the callback as the context and
       xml6_gbl_message_func() as the handler
    */
    void* ctx = (void*) callback;
    xmlGenericErrorFunc handler = (xmlGenericErrorFunc) _gbl_message_func;
    route(ctx, handler);
}

struct _xml6HandlerSave {
    void* serror_ctxt;
    xmlStructuredErrorFunc serror_handler;
    void* error_ctxt;
    xmlGenericErrorFunc error_handler;
};

typedef struct _xml6HandlerSave xml6HandlerSave;
typedef xml6HandlerSave *xml6HandlerSavePtr;

DLLEXPORT void* xml6_gbl_save_error_handlers(void) {
    xml6HandlerSavePtr save = (xml6HandlerSavePtr)xmlMalloc(sizeof(struct _xml6HandlerSave));
    save->serror_ctxt = xmlStructuredErrorContext;
    save->serror_handler = xmlStructuredError;
    save->error_ctxt = xmlGenericErrorContext;
    save->error_handler = xmlGenericError;
    return (void*)save;
}

DLLEXPORT void xml6_gbl_restore_error_handlers(void* ptr) {
    xml6HandlerSavePtr save = (xml6HandlerSavePtr)ptr;
    xmlStructuredErrorContext = save->serror_ctxt;
    xmlStructuredError = save->serror_handler;
    xmlGenericErrorContext = save->error_ctxt;
    xmlGenericError = save->error_handler;
    free(save);
}
