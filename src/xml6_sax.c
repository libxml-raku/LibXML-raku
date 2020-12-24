#include "xml6.h"
#include "xml6_sax.h"

DLLEXPORT void xml6_sax_set_internalSubset(xmlSAXHandlerPtr self, internalSubsetSAXFunc func) {
    self->internalSubset = func;
}

DLLEXPORT void xml6_sax_set_isStandalone(xmlSAXHandlerPtr self, isStandaloneSAXFunc func) {
    self->isStandalone = func;
}

DLLEXPORT void xml6_sax_set_hasInternalSubset(xmlSAXHandlerPtr self, hasInternalSubsetSAXFunc func) {
    self->hasInternalSubset = func;
}

DLLEXPORT void xml6_sax_set_hasExternalSubset(xmlSAXHandlerPtr self, hasExternalSubsetSAXFunc func) {
    self->hasExternalSubset = func;
}

DLLEXPORT void xml6_sax_set_resolveEntity(xmlSAXHandlerPtr self, resolveEntitySAXFunc func) {
    self->resolveEntity = func;
}

DLLEXPORT void xml6_sax_set_getEntity(xmlSAXHandlerPtr self, getEntitySAXFunc func) {
    self->getEntity = func;
}

DLLEXPORT void xml6_sax_set_entityDecl(xmlSAXHandlerPtr self, entityDeclSAXFunc func) {
    self->entityDecl = func;
}

DLLEXPORT void xml6_sax_set_notationDecl(xmlSAXHandlerPtr self, notationDeclSAXFunc func) {
    self->notationDecl = func;
}

DLLEXPORT void xml6_sax_set_attributeDecl(xmlSAXHandlerPtr self, attributeDeclSAXFunc func) {
    self->attributeDecl = func;
}

DLLEXPORT void xml6_sax_set_elementDecl(xmlSAXHandlerPtr self, elementDeclSAXFunc func) {
    self->elementDecl = func;
}

DLLEXPORT void xml6_sax_set_unparsedEntityDecl(xmlSAXHandlerPtr self, unparsedEntityDeclSAXFunc func) {
    self->unparsedEntityDecl = func;
}

DLLEXPORT void xml6_sax_set_setDocumentLocator(xmlSAXHandlerPtr self, setDocumentLocatorSAXFunc func) {
    self->setDocumentLocator = func;
}

DLLEXPORT void xml6_sax_set_startDocument(xmlSAXHandlerPtr self, startDocumentSAXFunc func) {
    self->startDocument = func;
}

DLLEXPORT void xml6_sax_set_endDocument(xmlSAXHandlerPtr self, endDocumentSAXFunc func) {
    self->endDocument = func;
}

DLLEXPORT void xml6_sax_set_startElement(xmlSAXHandlerPtr self, startElementSAXFunc func) {
    self->startElementNs = NULL;
    self->startElement = func;
}

DLLEXPORT void xml6_sax_set_endElement(xmlSAXHandlerPtr self, endElementSAXFunc func) {
    self->endElementNs = NULL;
    self->endElement = func;
}

DLLEXPORT void xml6_sax_set_reference(xmlSAXHandlerPtr self, referenceSAXFunc func) {
  self->reference = func;
}

DLLEXPORT void xml6_sax_set_characters(xmlSAXHandlerPtr self, charactersSAXFunc func) {
  self->characters = func;
}

DLLEXPORT void xml6_sax_set_ignorableWhitespace(xmlSAXHandlerPtr self, ignorableWhitespaceSAXFunc func) {
  self->ignorableWhitespace = func;
}

DLLEXPORT void xml6_sax_set_processingInstruction(xmlSAXHandlerPtr self, processingInstructionSAXFunc func) {
  self->processingInstruction = func;
}

DLLEXPORT void xml6_sax_set_comment(xmlSAXHandlerPtr self, commentSAXFunc func) {
  self->comment = func;
}

DLLEXPORT void xml6_sax_set_warning(xmlSAXHandlerPtr self, warningSAXFunc func) {
  self->warning = func;
}

DLLEXPORT void xml6_sax_set_error(xmlSAXHandlerPtr self, errorSAXFunc func) {
  self->error = func;
}

DLLEXPORT void xml6_sax_set_fatalError(xmlSAXHandlerPtr self, fatalErrorSAXFunc func) {
  self->fatalError = func;
}

DLLEXPORT void xml6_sax_set_getParameterEntity(xmlSAXHandlerPtr self, getParameterEntitySAXFunc func) {
  self->getParameterEntity = func;
}

DLLEXPORT void xml6_sax_set_cdataBlock(xmlSAXHandlerPtr self, cdataBlockSAXFunc func) {
  self->cdataBlock = func;
}

DLLEXPORT void xml6_sax_set_externalSubset(xmlSAXHandlerPtr self, externalSubsetSAXFunc func) {
  self->externalSubset = func;
}

DLLEXPORT void xml6_sax_set_startElementNs(xmlSAXHandlerPtr self, startElementNsSAX2Func func) {
  self->startElementNs = func;
}

DLLEXPORT void xml6_sax_set_endElementNs(xmlSAXHandlerPtr self, endElementNsSAX2Func func) {
  self->endElementNs = func;
}

DLLEXPORT void xml6_sax_set_serror(xmlSAXHandlerPtr self, xmlStructuredErrorFunc func) {
  self->serror = func;
}

// SaxLocator Methods

DLLEXPORT void xml6_sax_locator_init(xmlSAXLocatorPtr self) {
  self->getPublicId = xmlDefaultSAXLocator.getPublicId;
  self->getSystemId = xmlDefaultSAXLocator.getSystemId;
  self->getLineNumber = xmlDefaultSAXLocator.getLineNumber;
  self->getColumnNumber = xmlDefaultSAXLocator.getColumnNumber;
}

DLLEXPORT void xml6_sax_locator_set_getPublicId(xmlSAXLocatorPtr self, void *func) {
  self->getPublicId = func;
}

DLLEXPORT void xml6_sax_locator_set_getSystemId(xmlSAXLocatorPtr self, void *func) {
  self->getSystemId = func;
}

DLLEXPORT void xml6_sax_locator_set_getLineNumber(xmlSAXLocatorPtr self, void *func) {
  self->getLineNumber = func;
}

DLLEXPORT void xml6_sax_locator_set_getColumnNumber(xmlSAXLocatorPtr self, void *func) {
  self->getColumnNumber = func;
}

