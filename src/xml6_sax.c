#include "xml6.h"
#include "xml6_sax.h"

DLLEXPORT void xml6_sax_set_internalSubset(xmlSAXHandlerPtr sax, internalSubsetSAXFunc func) {
  sax->internalSubset = func;
}

DLLEXPORT void xml6_sax_set_isStandalone(xmlSAXHandlerPtr sax, isStandaloneSAXFunc func) {
  sax->isStandalone = func;
}

DLLEXPORT void xml6_sax_set_hasInternalSubset(xmlSAXHandlerPtr sax, hasInternalSubsetSAXFunc func) {
  sax->hasInternalSubset = func;
}

DLLEXPORT void xml6_sax_set_hasExternalSubset(xmlSAXHandlerPtr sax, hasExternalSubsetSAXFunc func) {
  sax->hasExternalSubset = func;
}

DLLEXPORT void xml6_sax_set_resolveEntity(xmlSAXHandlerPtr sax, resolveEntitySAXFunc func) {
  sax->resolveEntity = func;
}

DLLEXPORT void xml6_sax_set_getEntity(xmlSAXHandlerPtr sax, getEntitySAXFunc func) {
  sax->getEntity = func;
}

DLLEXPORT void xml6_sax_set_entityDecl(xmlSAXHandlerPtr sax, entityDeclSAXFunc func) {
  sax->entityDecl = func;
}

DLLEXPORT void xml6_sax_set_notationDecl(xmlSAXHandlerPtr sax, notationDeclSAXFunc func) {
  sax->notationDecl = func;
}

DLLEXPORT void xml6_sax_set_attributeDecl(xmlSAXHandlerPtr sax, attributeDeclSAXFunc func) {
  sax->attributeDecl = func;
}

DLLEXPORT void xml6_sax_set_unparsedEntityDecl(xmlSAXHandlerPtr sax, unparsedEntityDeclSAXFunc func) {
  sax->unparsedEntityDecl = func;
}

DLLEXPORT void xml6_sax_set_setDocumentLocator(xmlSAXHandlerPtr sax, setDocumentLocatorSAXFunc func) {
  sax->setDocumentLocator = func;
}

DLLEXPORT void xml6_sax_set_startDocument(xmlSAXHandlerPtr sax, startDocumentSAXFunc func) {
  sax->startDocument = func;
}

DLLEXPORT void xml6_sax_set_endDocument(xmlSAXHandlerPtr sax, endDocumentSAXFunc func) {
  sax->endDocument = func;
}

DLLEXPORT void xml6_sax_set_startElement(xmlSAXHandlerPtr sax, startElementSAXFunc func) {
  sax->startElement = func;
}

DLLEXPORT void xml6_sax_set_endElement(xmlSAXHandlerPtr sax, endElementSAXFunc func) {
  sax->endElement = func;
}

DLLEXPORT void xml6_sax_set_reference(xmlSAXHandlerPtr sax, referenceSAXFunc func) {
  sax->reference = func;
}

DLLEXPORT void xml6_sax_set_characters(xmlSAXHandlerPtr sax, charactersSAXFunc func) {
  sax->characters = func;
}

DLLEXPORT void xml6_sax_set_ignorableWhitespace(xmlSAXHandlerPtr sax, ignorableWhitespaceSAXFunc func) {
  sax->ignorableWhitespace = func;
}

DLLEXPORT void xml6_sax_set_processingInstruction(xmlSAXHandlerPtr sax, processingInstructionSAXFunc func) {
  sax->processingInstruction = func;
}

DLLEXPORT void xml6_sax_set_comment(xmlSAXHandlerPtr sax, commentSAXFunc func) {
  sax->comment = func;
}

DLLEXPORT void xml6_sax_set_warning(xmlSAXHandlerPtr sax, warningSAXFunc func) {
  sax->warning = func;
}

DLLEXPORT void xml6_sax_set_error(xmlSAXHandlerPtr sax, errorSAXFunc func) {
  sax->error = func;
}

DLLEXPORT void xml6_sax_set_fatalError(xmlSAXHandlerPtr sax, fatalErrorSAXFunc func) {
  sax->fatalError = func;
}

DLLEXPORT void xml6_sax_set_getParameterEntity(xmlSAXHandlerPtr sax, getParameterEntitySAXFunc func) {
  sax->getParameterEntity = func;
}

DLLEXPORT void xml6_sax_set_cdataBlock(xmlSAXHandlerPtr sax, cdataBlockSAXFunc func) {
  sax->cdataBlock = func;
}

DLLEXPORT void xml6_sax_set_externalSubset(xmlSAXHandlerPtr sax, externalSubsetSAXFunc func) {
  sax->externalSubset = func;
}

DLLEXPORT void xml6_sax_set_startElementNs(xmlSAXHandlerPtr sax, startElementNsSAX2Func func) {
  sax->startElementNs = func;
}

DLLEXPORT void xml6_sax_set_endElementNs(xmlSAXHandlerPtr sax, endElementNsSAX2Func func) {
  sax->endElementNs = func;
}

DLLEXPORT void xml6_sax_set_serror(xmlSAXHandlerPtr sax, xmlStructuredErrorFunc func) {
  sax->serror = func;
}

