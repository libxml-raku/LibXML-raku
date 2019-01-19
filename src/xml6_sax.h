#ifndef __XML6_SAX_H
#define __XML6_SAX_H

#include <libxml/parser.h>

DLLEXPORT void xml6_sax_set_internalSubset(xmlSAXHandlerPtr sax, internalSubsetSAXFunc func);

DLLEXPORT void xml6_sax_set_isStandalone(xmlSAXHandlerPtr sax, isStandaloneSAXFunc func);

DLLEXPORT void xml6_sax_set_hasInternalSubset(xmlSAXHandlerPtr sax, hasInternalSubsetSAXFunc func);

DLLEXPORT void xml6_sax_set_hasExternalSubset(xmlSAXHandlerPtr sax, hasExternalSubsetSAXFunc func);

DLLEXPORT void xml6_sax_set_resolveEntity(xmlSAXHandlerPtr sax, resolveEntitySAXFunc func);

DLLEXPORT void xml6_sax_set_getEntity(xmlSAXHandlerPtr sax, getEntitySAXFunc func);

DLLEXPORT void xml6_sax_set_entityDecl(xmlSAXHandlerPtr sax, entityDeclSAXFunc func);

DLLEXPORT void xml6_sax_set_notationDecl(xmlSAXHandlerPtr sax, notationDeclSAXFunc func);

DLLEXPORT void xml6_sax_set_attributeDecl(xmlSAXHandlerPtr sax, attributeDeclSAXFunc func);

DLLEXPORT void xml6_sax_set_unparsedEntityDecl(xmlSAXHandlerPtr sax, unparsedEntityDeclSAXFunc func);

DLLEXPORT void xml6_sax_set_setDocumentLocator(xmlSAXHandlerPtr sax, setDocumentLocatorSAXFunc func);

DLLEXPORT void xml6_sax_set_startDocument(xmlSAXHandlerPtr sax, startDocumentSAXFunc func);

DLLEXPORT void xml6_sax_set_endDocument(xmlSAXHandlerPtr sax, endDocumentSAXFunc func);

DLLEXPORT void xml6_sax_set_startElement(xmlSAXHandlerPtr sax, startElementSAXFunc func);

DLLEXPORT void xml6_sax_set_endElement(xmlSAXHandlerPtr sax, endElementSAXFunc func);

DLLEXPORT void xml6_sax_set_reference(xmlSAXHandlerPtr sax, referenceSAXFunc func);

DLLEXPORT void xml6_sax_set_characters(xmlSAXHandlerPtr sax, charactersSAXFunc func);

DLLEXPORT void xml6_sax_set_ignorableWhitespace(xmlSAXHandlerPtr sax, ignorableWhitespaceSAXFunc func);

DLLEXPORT void xml6_sax_set_processingInstruction(xmlSAXHandlerPtr sax, processingInstructionSAXFunc func);

DLLEXPORT void xml6_sax_set_comment(xmlSAXHandlerPtr sax, commentSAXFunc func);

DLLEXPORT void xml6_sax_set_warning(xmlSAXHandlerPtr sax, warningSAXFunc func);

DLLEXPORT void xml6_sax_set_error(xmlSAXHandlerPtr sax, errorSAXFunc func);

DLLEXPORT void xml6_sax_set_fatalError(xmlSAXHandlerPtr sax, fatalErrorSAXFunc func);

DLLEXPORT void xml6_sax_set_getParameterEntity(xmlSAXHandlerPtr sax, getParameterEntitySAXFunc func);

DLLEXPORT void xml6_sax_set_cdataBlock(xmlSAXHandlerPtr sax, cdataBlockSAXFunc func);

DLLEXPORT void xml6_sax_set_externalSubset(xmlSAXHandlerPtr sax, externalSubsetSAXFunc func);

DLLEXPORT void xml6_sax_set_startElementNs(xmlSAXHandlerPtr sax, startElementNsSAX2Func func);

DLLEXPORT void xml6_sax_set_endElementNs(xmlSAXHandlerPtr sax, endElementNsSAX2Func func);

DLLEXPORT void xml6_sax_set_serror(xmlSAXHandlerPtr sax, xmlStructuredErrorFunc func);

#endif /* __XML6_SAX_H */
