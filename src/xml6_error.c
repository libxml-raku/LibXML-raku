#include "xml6.h"
#include "xml6_error.h"
#include <libxml/parser.h>

DLLEXPORT xmlChar*
xml6_error_context_and_column(xmlErrorPtr self, unsigned int* column) {
    xmlParserInputPtr input;
    const xmlChar *cur, *base, *col_cur;
    unsigned int n, col;
    xmlChar  content[81]; /* space for 80 chars + null terminator */
    xmlChar *ctnt;
    int domain = self->domain;
    xmlParserCtxtPtr ctxt = NULL;

    if ((domain == XML_FROM_PARSER) || (domain == XML_FROM_HTML) ||
        (domain == XML_FROM_DTD) || (domain == XML_FROM_NAMESPACE) ||
        (domain == XML_FROM_IO) || (domain == XML_FROM_VALID)) {
        ctxt = (xmlParserCtxtPtr) self->ctxt;
    }
    if (ctxt == NULL) {
        return NULL;
    }
    input = ctxt->input;
    if ((input != NULL) && (input->filename == NULL) &&
        (ctxt->inputNr > 1)) {
        input = ctxt->inputTab[ctxt->inputNr - 2];
    }
    if (input == NULL) {
        return NULL;
    }
    cur = input->cur;
    base = input->base;
    /* skip backwards over any end-of-lines */
    while ((cur > base) && ((*(cur) == '\n') || (*(cur) == '\r'))) {
        cur--;
    }
    n = 0;
    /* search backwards for beginning-of-line (to max buff size) */
    while ((n++ < (sizeof(content)-1)) && (cur > base) &&
           (*(cur) != '\n') && (*(cur) != '\r'))
        cur--;
    /* search backwards for beginning-of-line for calculating the
     * column. */
    col_cur = cur;
    while ((col_cur > base) && (*(col_cur) != '\n') && (*(col_cur) != '\r'))
        col_cur--;
    if ((*(cur) == '\n') || (*(cur) == '\r')) cur++;
    if ((*(col_cur) == '\n') || (*(col_cur) == '\r')) col_cur++;
    /* calculate the error position in terms of the current position */
    col = input->cur - col_cur;
    /* search forward for end-of-line (to max buff size) */
    n = 0;
    ctnt = content;
    /* copy selected text to our buffer */
    while ((*cur != 0) && (*(cur) != '\n') &&
           (*(cur) != '\r') && (n < sizeof(content)-1)) {
        *ctnt++ = *cur++;
        n++;
    }
    *ctnt = 0;
    *column = col;
    return xmlStrdup(content);
}
