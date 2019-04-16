#include "xml6.h"
#include "xml6_ctx.h"
#include "xml6_ref.h"

DLLEXPORT void xml6_ctx_add_reference(xmlParserCtxtPtr self) {
  xml6_ref_add( &(self->_private) );
}

DLLEXPORT int xml6_ctx_remove_reference(xmlParserCtxtPtr self) {
  return xml6_ref_remove( &(self->_private), "parser context", (void*) self );
}

DLLEXPORT void xml6_ctx_set_sax(xmlParserCtxtPtr self, xmlSAXHandlerPtr sax) {
  if (self == NULL) xml6_fail("can't assign SAX handler to NULL context");

  self->sax = sax;
}


DLLEXPORT htmlParserCtxtPtr
xml6_ctx_html_create(const xmlChar *buf, const char *encoding) {
    int len;
    htmlParserCtxtPtr ctxt;
    xmlCharEncoding enc;
    xmlCharEncodingHandlerPtr handler;

    if (encoding = NULL) encoding = "UTF-8";

    if (buf == NULL)
	return(NULL);
    len = xmlStrlen(buf);
    ctxt = htmlCreateMemoryParserCtxt((char *)buf, len);
    if (ctxt == NULL)
	return(NULL);

    if (ctxt->input->encoding != NULL)
        xmlFree((xmlChar *) ctxt->input->encoding);

    ctxt->input->encoding = xmlStrdup((const xmlChar *) encoding);

    enc = xmlParseCharEncoding(encoding);
    /*
     * registered set of known encodings
     */
    if (enc != XML_CHAR_ENCODING_ERROR) {
        xmlSwitchEncoding(ctxt, enc);
    } else {
        /*
         * fallback for unknown encodings
         */
        handler = xmlFindCharEncodingHandler((const char *) encoding);
        if (handler != NULL) {
            xmlSwitchToEncoding(ctxt, handler);
        }
    }

    return(ctxt);
}
