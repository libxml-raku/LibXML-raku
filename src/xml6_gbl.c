#include "xml6.h"
#include "xml6_gbl.h"
#include <libxml/parser.h>
#include <libxml/threads.h>
#include <libxml/xmlIO.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>

static xmlExternalEntityLoader _default_ext_entity_loader = NULL;
static xmlDictPtr _dict = NULL;
static xmlMutexPtr _dict_mutex = NULL;

DLLEXPORT void xml6_gbl_init(void) {
    assert(_default_ext_entity_loader == NULL);
    assert(_dict == NULL);
    assert(_dict_mutex == NULL);
    _default_ext_entity_loader = xmlGetExternalEntityLoader();
    _dict_mutex = xmlNewMutex();
    _dict = xmlDictCreate();
}

DLLEXPORT void* xml6_gbl_get_external_entity_loader(void) {
    return xmlGetExternalEntityLoader();
}

DLLEXPORT void xml6_gbl_set_external_entity_loader(void *loader) {
    xmlSetExternalEntityLoader(loader);
}

DLLEXPORT int xml6_gbl_set_external_entity_loader_net(int net) {
    int update = 0;

    if (net) {
        update = xmlGetExternalEntityLoader() == xmlNoNetExternalEntityLoader;
        if (update) xmlSetExternalEntityLoader(_default_ext_entity_loader);
    }
    else {
        update = xmlGetExternalEntityLoader() == _default_ext_entity_loader;
        if (update) xmlSetExternalEntityLoader(xmlNoNetExternalEntityLoader);
    }

    return update;
}

/*
 * Note: xmlSaveNoEmptyTags, xmlKeepBlanksDefaultValue and
 * xmlLastError are macros defined in libxml/globals.h.
 * When threading is enabled they expand to:
 * - (*(__xmlSaveNoEmptyTags()))
 * - (*(__xmlKeepBlanksDefaultValue()))
 * - (*(__xmlLastError()))
 * which are scoped to OS threads.
 * Note: Rakudo high-level threads are not bound to OS threads, for example 
 * https://github.com/libxml-raku/LibXML-raku/issues/13#issuecomment-1140570095
 */

DLLEXPORT int xml6_gbl_os_thread_get_tag_expansion(void) {
    return xmlSaveNoEmptyTags;
}

DLLEXPORT void xml6_gbl_os_thread_set_tag_expansion(int flag) {
    xmlSaveNoEmptyTags = flag;
}

DLLEXPORT int xml6_gbl_os_thread_get_keep_blanks(void) {
    return xmlKeepBlanksDefaultValue;
}

DLLEXPORT void xml6_gbl_os_thread_set_keep_blanks(int flag) {
    xmlKeepBlanksDefaultValue = flag;
}

DLLEXPORT xmlError* xml6_gbl_os_thread_get_last_error(void) {
    return &xmlLastError;
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

DLLEXPORT void xml6_gbl_set_os_thread_generic_error_handler(xml6_gbl_MessageCallback callback,  void (*setter)(void*, xmlGenericErrorFunc)) {
    /* we actually set the callback as the context and
       xml6_gbl_message_func() as the handler
    */
    void* ctx = (void*) callback;
    xmlGenericErrorFunc handler = (xmlGenericErrorFunc) _gbl_message_func;
    xmlSetGenericErrorFunc(ctx, handler);
}

struct _xml6HandlerSave {
    void* serror_ctxt;
    xmlStructuredErrorFunc serror_handler;
    void* error_ctxt;
    xmlGenericErrorFunc error_handler;
};

typedef struct _xml6HandlerSave xml6HandlerSave;
typedef xml6HandlerSave *xml6HandlerSavePtr;

/*
 * These are also thread-safe macros:
 * 	xmlStructuredErrorContext, xmlStructuredErrorContext
 *      xmlGenericErrorContext, xmlGenericError
 */

DLLEXPORT void* xml6_gbl_save_error_handlers(void) {
    xml6HandlerSavePtr save = (xml6HandlerSavePtr)xmlMalloc(sizeof(struct _xml6HandlerSave));
    save->serror_ctxt = xmlStructuredErrorContext;
    save->serror_handler = xmlStructuredError;
    save->error_ctxt = xmlGenericErrorContext;
    save->error_handler = xmlGenericError;
    return (void*)save;
}

DLLEXPORT void xml6_gbl_restore_error_handlers(void* ptr) {
    if (ptr != NULL) {
        xml6HandlerSavePtr save = (xml6HandlerSavePtr)ptr;
        xmlStructuredErrorContext = save->serror_ctxt;
        xmlStructuredError = save->serror_handler;
        xmlGenericErrorContext = save->error_ctxt;
        xmlGenericError = save->error_handler;
        free(save);
    }
}

DLLEXPORT const xmlChar* xml6_gbl_cache(xmlChar* word) {
    const xmlChar *key = NULL;

    if (word != NULL) {
        assert(_dict != NULL);

        xmlMutexLock(_dict_mutex);
        key = xmlDictLookup(_dict, word, -1);
        xmlMutexUnlock(_dict_mutex);

        if (key != word) {
            xmlFree(word);
        }
    }
    return key;
}

DLLEXPORT const xmlChar* xml6_gbl_cache_dup(const xmlChar* word) {
    const xmlChar *key = NULL;

    if (word != NULL) {
        int word_len = strlen((char*)word);
        assert(_dict != NULL);

        xmlMutexLock(_dict_mutex);
        if (!xmlDictExists(_dict, word, word_len)) {
            word = xmlStrdup(word);
        }
        key = xmlDictLookup(_dict, word, word_len);
        xmlMutexUnlock(_dict_mutex);
    }
    return key;
}
