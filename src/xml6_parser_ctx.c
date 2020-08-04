#include "xml6.h"
#include "xml6_parser_ctx.h"
#include "xml6_ref.h"
#include <assert.h>

DLLEXPORT void xml6_parser_ctx_add_reference(xmlParserCtxtPtr self) {
    assert(self != NULL);
    xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_parser_ctx_remove_reference(xmlParserCtxtPtr self) {
    assert(self != NULL);
    return xml6_ref_remove( &(self->_private), "parser context", (void*) self );
}

DLLEXPORT void xml6_parser_ctx_set_sax(xmlParserCtxtPtr self, xmlSAXHandlerPtr sax) {
    assert(self != NULL);
    self->sax = sax;
}

DLLEXPORT void xml6_parser_ctx_set_myDoc(xmlParserCtxtPtr self, xmlDocPtr doc) {
    assert(self != NULL);
    if (self->myDoc && self->myDoc != doc) {
        xml6_warn("possible memory leak in setting ctx->myDoc");
    }
    self->myDoc = doc;
}

DLLEXPORT htmlParserCtxtPtr
xml6_parser_ctx_html_create_str(const xmlChar *str, const char *encoding) {

    int len;
    if (str == NULL)
	return(NULL);

    len = xmlStrlen(str);
    return xml6_parser_ctx_html_create_buf(str, len, encoding);
}

DLLEXPORT htmlParserCtxtPtr
xml6_parser_ctx_html_create_buf(const xmlChar *buf, int len, const char *encoding) {
    htmlParserCtxtPtr ctxt;

    if (encoding == NULL) encoding = "UTF-8";

    ctxt = htmlCreateMemoryParserCtxt((char *)buf, len);

    if (ctxt != NULL) {
        xmlCharEncoding enc = xmlParseCharEncoding(encoding);

        if (ctxt->input->encoding != NULL)
            xmlFree((xmlChar *) ctxt->input->encoding);

        ctxt->input->encoding = xmlStrdup((const xmlChar *) encoding);

      
        /*
         * registered set of known encodings
         */
        if (enc != XML_CHAR_ENCODING_ERROR) {
            xmlSwitchEncoding(ctxt, enc);
        } else {
            /*
             * fallback for unknown encodings
             */
            xmlCharEncodingHandlerPtr handler = xmlFindCharEncodingHandler((const char *) encoding);
            if (handler != NULL) {
                xmlSwitchToEncoding(ctxt, handler);
            }
        }
    }

    return(ctxt);
}

DLLEXPORT int
xml6_parser_ctx_close(xmlParserCtxtPtr self) {
    int i;
    int compressed = 0;
    for (i = self->inputNr - 1; i >= 0; i--) {
        xmlParserInputPtr input = self->inputTab[i];
        xmlParserInputBufferPtr buf = input->buf;
        if (buf != NULL) {
            if (buf->compressed != 0) {
                compressed = 1;
            }
            xmlFreeParserInputBuffer(buf);
            input->buf = NULL;
        }
    }
    return compressed;
}
