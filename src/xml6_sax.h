#ifndef __XML6_SAX_H
#define __XML6_SAX_H

#include <libxml/parser.h>

DLLEXPORT void xml6_sax_set_internalSubset(xmlSAXHandlerPtr, internalSubsetSAXFunc);

DLLEXPORT void xml6_sax_set_isStandalone(xmlSAXHandlerPtr, isStandaloneSAXFunc);

DLLEXPORT void xml6_sax_set_hasInternalSubset(xmlSAXHandlerPtr, hasInternalSubsetSAXFunc);

DLLEXPORT void xml6_sax_set_hasExternalSubset(xmlSAXHandlerPtr, hasExternalSubsetSAXFunc);

DLLEXPORT void xml6_sax_set_resolveEntity(xmlSAXHandlerPtr, resolveEntitySAXFunc);

DLLEXPORT void xml6_sax_set_getEntity(xmlSAXHandlerPtr, getEntitySAXFunc);

DLLEXPORT void xml6_sax_set_entityDecl(xmlSAXHandlerPtr, entityDeclSAXFunc);

DLLEXPORT void xml6_sax_set_elementDecl(xmlSAXHandlerPtr, elementDeclSAXFunc);

DLLEXPORT void xml6_sax_set_notationDecl(xmlSAXHandlerPtr, notationDeclSAXFunc);

DLLEXPORT void xml6_sax_set_attributeDecl(xmlSAXHandlerPtr, attributeDeclSAXFunc);

DLLEXPORT void xml6_sax_set_unparsedEntityDecl(xmlSAXHandlerPtr, unparsedEntityDeclSAXFunc);

DLLEXPORT void xml6_sax_set_setDocumentLocator(xmlSAXHandlerPtr, setDocumentLocatorSAXFunc);

DLLEXPORT void xml6_sax_set_startDocument(xmlSAXHandlerPtr, startDocumentSAXFunc);

DLLEXPORT void xml6_sax_set_endDocument(xmlSAXHandlerPtr, endDocumentSAXFunc);

DLLEXPORT void xml6_sax_set_startElement(xmlSAXHandlerPtr, startElementSAXFunc);

DLLEXPORT void xml6_sax_set_endElement(xmlSAXHandlerPtr, endElementSAXFunc);

DLLEXPORT void xml6_sax_set_reference(xmlSAXHandlerPtr, referenceSAXFunc);

DLLEXPORT void xml6_sax_set_characters(xmlSAXHandlerPtr, charactersSAXFunc);

DLLEXPORT void xml6_sax_set_ignorableWhitespace(xmlSAXHandlerPtr, ignorableWhitespaceSAXFunc);

DLLEXPORT void xml6_sax_set_processingInstruction(xmlSAXHandlerPtr, processingInstructionSAXFunc);

DLLEXPORT void xml6_sax_set_comment(xmlSAXHandlerPtr, commentSAXFunc);

DLLEXPORT void xml6_sax_set_warning(xmlSAXHandlerPtr, warningSAXFunc);

DLLEXPORT void xml6_sax_set_error(xmlSAXHandlerPtr, errorSAXFunc);

DLLEXPORT void xml6_sax_set_fatalError(xmlSAXHandlerPtr, fatalErrorSAXFunc);

DLLEXPORT void xml6_sax_set_getParameterEntity(xmlSAXHandlerPtr, getParameterEntitySAXFunc);

DLLEXPORT void xml6_sax_set_cdataBlock(xmlSAXHandlerPtr, cdataBlockSAXFunc);

DLLEXPORT void xml6_sax_set_externalSubset(xmlSAXHandlerPtr, externalSubsetSAXFunc);

DLLEXPORT void xml6_sax_set_startElementNs(xmlSAXHandlerPtr, startElementNsSAX2Func);

DLLEXPORT void xml6_sax_set_endElementNs(xmlSAXHandlerPtr, endElementNsSAX2Func);

DLLEXPORT void xml6_sax_set_serror(xmlSAXHandlerPtr, xmlStructuredErrorFunc);

// SaxLocator methods

DLLEXPORT void xml6_sax_locator_init(xmlSAXLocatorPtr);

DLLEXPORT void xml6_sax_locator_set_getPublicId(xmlSAXLocatorPtr, void *func);

DLLEXPORT void xml6_sax_locator_set_getSystemId(xmlSAXLocatorPtr, void *func);

DLLEXPORT void xml6_sax_locator_set_getLineNumber(xmlSAXLocatorPtr, void *func);

DLLEXPORT void xml6_sax_locator_set_getColumnNumber(xmlSAXLocatorPtr, void *func);

#endif /* __XML6_SAX_H */
