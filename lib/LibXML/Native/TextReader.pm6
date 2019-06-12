unit module LibXML::Native::TextReader;

use NativeCall;
use LibXML::Native;
use LibXML::Types :QName;

constant Stub = LibXML::Native::Stub;
constant LIB  = LibXML::Native::LIB;
constant BIND-LIB = LibXML::Native::BIND-LIB;
constant xmlCharP = LibXML::Native::xmlCharP;

sub xml6_gbl_have_libxml_reader(--> int32) is native(BIND-LIB) is export {*}

class xmlTextReader is repr('CPointer') is export {

    sub xmlNewTextReader(xmlParserInputBuffer, Str $uri --> xmlTextReader) is native(LIB) {*}
    sub xmlNewTextReaderFilename(Str --> xmlTextReader) is native(LIB) {*}
    sub xmlReaderWalker(xmlDoc --> xmlTextReader) is native(LIB) {*}

    sub xmlReaderForFd(int32, Str, Str, int32 -->  xmlTextReader) is native(LIB) {*}

    method attributeCount(--> int32) is native(LIB) is symbol('xmlTextReaderAttributeCount') {*}
    method baseURI(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstBaseUri') {*}
    method byteConsumed(--> ulong) is native(LIB) is symbol('xmlTextReaderByteConsumed') {*}
    method close(--> int32) is native(LIB) is symbol('xmlTextReaderClose') {*}
    method columnNumber(--> int32) is native(LIB) is symbol('xmlTextReaderGetParserColumnNumber') {*}
    method currentDoc(--> xmlDoc) is native(LIB) is symbol('xmlTextReaderCurrentDoc') {*}
    method currentNode(--> domNode) is native(LIB) is symbol('xmlTextReaderCurrentNode') {*}
    method currentNodeTree(--> domNode) is native(LIB) is symbol('xmlTextReaderExpand') {*}
    method depth(--> int32) is native(LIB) is symbol('xmlTextReaderDepth') {*}
    method getAttribute(QName --> xmlCharP) is native(LIB) is symbol('xmlTextReaderGetAttribute') {*}
    method getAttributeNo(int32 --> xmlCharP) is native(LIB) is symbol('xmlTextReaderGetAttributeNo') {*}
    method getAttributeNs(QName, Str --> xmlCharP) is native(LIB) is symbol('xmlTextReaderGetAttributeNs') {*}
    method encoding(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstEncoding') {*}
    method finish(--> int32) is native(BIND-LIB) is symbol('xml6_reader_finish') {*}
    method getParserProp(int32 --> int32) is native(LIB) is symbol('xmlTextReaderGetParserProp') {*}
    method hasAttributes(--> int32) is native(LIB) is symbol('xmlTextReaderHasAttributes') {*}
    method hasValue(--> int32) is native(LIB) is symbol('xmlTextReaderHasValue') {*}
    method isDefault(--> int32) is native(LIB) is symbol('xmlTextReaderIsDefault') {*}
    method isEmptyElement(--> int32) is native(LIB) is symbol('xmlTextReaderIsEmptyElement') {*}
    method isNamespaceDecl(--> int32) is native(LIB) is symbol('xmlTextReaderIsNamespaceDecl') {*}
    method isValid(--> int32) is native(LIB) is symbol('xmlTextReaderIsValid') {*}
    method lineNumber(--> int32) is native(LIB) is symbol('xmlTextReaderGetParserLineNumber') {*}
    method localName(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstLocalName') {*}
    method lookupNamespace(QName --> xmlCharP) is native(LIB) is symbol('xmlTextReaderLookupNamespace') {*}
    method moveToAttribute(QName --> int32) is native(LIB) is symbol('xmlTextReaderMoveToAttribute') {*}
    method moveToAttributeNo(int32 --> int32) is native(LIB) is symbol('xmlTextReaderMoveToAttributeNo') {*}
    method moveToAttributeNs(QName, Str --> int32) is native(LIB) is symbol('xmlTextReaderMoveToAttributeNs') {*}
    method moveToElement(--> int32) is native(LIB) is symbol('xmlTextReaderMoveToElement') {*}
    method moveToFirstAttribute(--> int32) is native(LIB) is symbol('xmlTextReaderMoveToFirstAttribute') {*}
    method moveToNextAttribute(--> int32) is native(LIB) is symbol('xmlTextReaderMoveToNextAttribute') {*}
    method name(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstName') {*}
    method namespaceURI(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstNamespaceUri') {*}
    method next(--> int32) is native(BIND-LIB) is symbol('xmlTextReaderNext') {*}
    method nextElement(Str, Str --> int32) is native(BIND-LIB) is symbol('xml6_reader_next_element') {*}
    method nextSibling(--> int32) is native(BIND-LIB) is symbol('xml6_reader_next_sibling') {*}
    method nextSiblingElement(Str, Str --> int32) is native(BIND-LIB) is symbol('xml6_reader_next_sibling_element') {*}
    method nodeType(--> int32) is native(LIB) is symbol('xmlTextReaderNodeType') {*}
    method prefix(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstPrefix') {*}
    method preserveNode(--> domNode) is native(LIB) is symbol('xmlTextReaderPreserve') {*}
    method preservePattern(xmlCharP, CArray[Str] --> int32) is native(LIB) is symbol('xmlTextReaderPreservePattern') {*}
    method read(--> int32) is native(LIB) is symbol('xmlTextReaderRead') {*}
    method readAttributeValue(--> int32) is native(LIB) is symbol('xmlTextReaderReadAttributeValue') {*}
    method readInnerXml(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderReadInnerXml') {*}
    method readOuterXml(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderReadOuterXml') {*}
    method readState(--> int32) is native(LIB) is symbol('xmlTextReaderReadState') {*}
    method setStructuredErrorFunc( &error-func (Pointer $, xmlError $)) is native(LIB) is symbol('xmlTextReaderSetStructuredErrorHandler') {*};
    method skipSiblings(--> int32) is native(BIND-LIB) is symbol('xml6_reader_skip_siblings') {*}
    method standalone(--> int32) is native(LIB) is symbol('xmlTextReaderStandalone') {*}
    method value(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstValue') {*}
    method xmlLang(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstXmlLang') {*}
    method xmlVersion(--> xmlCharP) is native(LIB) is symbol('xmlTextReaderConstXmlVersion') {*}
    method Setup(xmlParserInputBuffer, Str $uri, Str $enc, int32 $opts --> int32) is symbol('xmlTextReaderSetup') is native(LIB) {*}
    method Free is symbol('xmlFreeTextReader') is native(LIB) {*}

    method setup(xmlParserInputBuffer :$buf, Str :$URI, xmlEncodingStr :$enc, UInt :$flags = 0) {
        $.Setup($buf, $URI, $enc, $flags);
    }

    multi method new(Str:D :$URI!) {
        xmlNewTextReaderFilename($URI);
    }
    multi method new(Str:D :$string!, xmlEncodingStr :$enc, Str :$URI) {
        my xmlParserInputBuffer:D $input .= new: :$string, :$enc;
        xmlNewTextReader($input, $URI);
    }
    multi method new(UInt:D :$fd!, Str :$URI, xmlEncodingStr :$enc, UInt :$flags = 0) {
        xmlReaderForFd( $fd, $URI, $enc, $flags);
    }
    multi method new(xmlDoc:D :$doc!) {
        xmlReaderWalker( $doc);
    }

    multi method new(|c) is default { fail c.perl }
}

