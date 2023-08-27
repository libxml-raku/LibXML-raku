#include "xml6.h"
#include "xml6_gbl.h"
#include <libxml/parser.h>
#include <libxml/threads.h>
#include <libxml/xmlIO.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>

static xmlExternalEntityLoader _default_ext_entity_loader = NULL;
static xmlDictPtr _cache = NULL;
static xmlMutexPtr _cache_mutex = NULL;
#ifdef DEBUG
static int _cache_size = 0;
#endif

DLLEXPORT void xml6_gbl_init(void) {
    assert(_default_ext_entity_loader == NULL);
    assert(_cache == NULL);
    assert(_cache_mutex == NULL);
    _default_ext_entity_loader = xmlGetExternalEntityLoader();
    _cache_mutex = xmlNewMutex();
    _cache = xmlDictCreate();
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

DLLEXPORT void xml6_gbl_os_thread_xml_free(void* obj) {
    xmlFree(obj);
}

DLLEXPORT xmlError* xml6_gbl_os_thread_get_last_error(void) {
    return &xmlLastError;
}

DLLEXPORT xmlSAXLocatorPtr xml6_gbl_os_thread_get_default_sax_locator(void) {
    return &xmlDefaultSAXLocator;
}

static void _gbl_message_func(
    void* ctx,         // actually our callback...
    char* fmt, ...) {  // incoming vararg message
    va_list args;
    char msg[256];

    xml6_gbl_MessageCallback callback = (xml6_gbl_MessageCallback) ctx;

    va_start(args, fmt);
    vsnprintf(msg, 255, fmt, args);
    va_end(args);

    // invoke the error handling callback; pass arguments
    (*callback)(msg);
}

DLLEXPORT void xml6_gbl_set_os_thread_generic_error_handler(xml6_gbl_MessageCallback callback,  void (*setter)(void*, xmlGenericErrorFunc)) {
    /* we actually set the callback as the context and
       xml6_gbl_message_func() as the handler
    */
    void* ctx = (void*) callback;
    xmlGenericErrorFunc handler = (xmlGenericErrorFunc) _gbl_message_func;
    // setter could be: xmlSetGenericErrorFunc() or xsltSetGenericErrorFunc()
    setter(ctx, handler);
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
        xmlFree(save);
    }
}

DLLEXPORT const xmlChar* xml6_gbl_dict(xmlChar* word) {
    const xmlChar *rv = NULL;

    if (word != NULL) {
        assert(_cache != NULL);

        xmlMutexLock(_cache_mutex);
        rv = xmlDictLookup(_cache, word, -1);
        xmlMutexUnlock(_cache_mutex);
        xmlFree(word);
    }
    return rv;
}

DLLEXPORT const xmlChar* xml6_gbl_dict_dup(const xmlChar* word) {
    const xmlChar *key = NULL;

    if (word != NULL) {
        int word_len = strlen((char*)word);
        assert(_cache != NULL);

        xmlMutexLock(_cache_mutex);
        key = xmlDictExists(_cache, word, word_len);
        if (key == NULL) {
#ifdef DEBUG
            _cache_size++;
#endif
            key = xmlDictLookup(_cache, xmlStrdup(word), word_len);
        }
        xmlMutexUnlock(_cache_mutex);
    }
    return key;
}

DLLEXPORT int
xml6_gbl_dict_size(void) {
#ifdef DEBUG
    return _cache_size;
#else
    return -1;
#endif
}
