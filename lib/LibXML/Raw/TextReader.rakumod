unit module LibXML::Raw::TextReader;

use NativeCall;
use LibXML::Raw;
use LibXML::Raw::RelaxNG;
use LibXML::Raw::Schema;
use LibXML::Types :QName;
use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :Opaque, :xmlCharP;

sub xml6_config_have_libxml_reader(--> int32) is native($BIND-XML2) is export {*}

class xmlTextReader is repr('CPointer') is export {

    our sub NewBuf(xmlParserInputBuffer, Str $uri --> xmlTextReader) is native($XML2) is symbol('xmlNewTextReader') {*}
    our sub NewFile(Str, Str, int32 --> xmlTextReader) is native($XML2) is symbol('xmlNewTextReaderForFile') {*}
    our sub NewMemory(Blob, int32, Str, Str, int32 --> xmlTextReader) is native($XML2) is symbol('xmlReaderForMemory') {*}
    our sub NewDoc(xmlDoc --> xmlTextReader) is native($XML2) is symbol('xmlReaderWalker') {*}
    our sub NewFd(int32, Str, Str, int32 --> xmlTextReader) is native($XML2) is symbol('xmlReaderForFd') {*}

    method attributeCount(--> int32) is native($XML2) is symbol('xmlTextReaderAttributeCount') {*}
    method baseURI(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstBaseUri') {*}
    method byteConsumed(--> ulong) is native($XML2) is symbol('xmlTextReaderByteConsumed') {*}
    method close(--> int32) is native($XML2) is symbol('xmlTextReaderClose') {*}
    method columnNumber(--> int32) is native($XML2) is symbol('xmlTextReaderGetParserColumnNumber') {*}
    method currentDoc(--> xmlDoc) is native($XML2) is symbol('xmlTextReaderCurrentDoc') {*}
    method currentNode(--> anyNode) is native($XML2) is symbol('xmlTextReaderCurrentNode') {*}
    method currentNodeTree(--> anyNode) is native($XML2) is symbol('xmlTextReaderExpand') {*}
    method depth(--> int32) is native($XML2) is symbol('xmlTextReaderDepth') {*}
    method getAttribute(QName --> xmlCharP) is native($XML2) is symbol('xmlTextReaderGetAttribute') {*}
    method getAttributeNo(int32 --> xmlCharP) is native($XML2) is symbol('xmlTextReaderGetAttributeNo') {*}
    method getAttributeNs(QName, Str --> xmlCharP) is native($XML2) is symbol('xmlTextReaderGetAttributeNs') {*}
    method encoding(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstEncoding') {*}
    method finish(--> int32) is native($BIND-XML2) is symbol('xml6_reader_finish') {*}
    method getParserProp(int32 --> int32) is native($XML2) is symbol('xmlTextReaderGetParserProp') {*}
    method setParserProp(int32 $prop, int32 $value --> int32) is native($XML2) is symbol('xmlTextReaderSetParserProp') {*};

    method hasAttributes(--> int32) is native($XML2) is symbol('xmlTextReaderHasAttributes') {*}
    method hasValue(--> int32) is native($XML2) is symbol('xmlTextReaderHasValue') {*}
    method isDefault(--> int32) is native($XML2) is symbol('xmlTextReaderIsDefault') {*}
    method isEmptyElement(--> int32) is native($XML2) is symbol('xmlTextReaderIsEmptyElement') {*}
    method isNamespaceDecl(--> int32) is native($XML2) is symbol('xmlTextReaderIsNamespaceDecl') {*}
    method isValid(--> int32) is native($XML2) is symbol('xmlTextReaderIsValid') {*}
    method lineNumber(--> int32) is native($XML2) is symbol('xmlTextReaderGetParserLineNumber') {*}
    method localName(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstLocalName') {*}
    method lookupNamespace(QName --> xmlCharP) is native($XML2) is symbol('xmlTextReaderLookupNamespace') {*}
    method moveToAttribute(QName --> int32) is native($XML2) is symbol('xmlTextReaderMoveToAttribute') {*}
    method moveToAttributeNo(int32 --> int32) is native($XML2) is symbol('xmlTextReaderMoveToAttributeNo') {*}
    method moveToAttributeNs(QName, Str --> int32) is native($XML2) is symbol('xmlTextReaderMoveToAttributeNs') {*}
    method moveToElement(--> int32) is native($XML2) is symbol('xmlTextReaderMoveToElement') {*}
    method moveToFirstAttribute(--> int32) is native($XML2) is symbol('xmlTextReaderMoveToFirstAttribute') {*}
    method moveToNextAttribute(--> int32) is native($XML2) is symbol('xmlTextReaderMoveToNextAttribute') {*}
    method name(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstName') {*}
    method namespaceURI(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstNamespaceUri') {*}
    method next(--> int32) is native($XML2) is symbol('xmlTextReaderNext') {*}
    method nextElement(Str, Str --> int32) is native($BIND-XML2) is symbol('xml6_reader_next_element') {*}
    method nextPatternMatch(xmlPattern --> int32) is native($BIND-XML2) is symbol('xml6_reader_next_pattern_match') {*}
    method nextSibling(--> int32) is native($BIND-XML2) is symbol('xml6_reader_next_sibling') {*}
    method nextSiblingElement(Str, Str --> int32) is native($BIND-XML2) is symbol('xml6_reader_next_sibling_element') {*}
    method nodeType(--> int32) is native($XML2) is symbol('xmlTextReaderNodeType') {*}
    method prefix(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstPrefix') {*}
    method preserveNode(--> anyNode) is native($XML2) is symbol('xmlTextReaderPreserve') {*}
    method preservePattern(xmlCharP, CArray[Str] --> int32) is native($XML2) is symbol('xmlTextReaderPreservePattern') {*}
    method read(--> int32) is native($XML2) is symbol('xmlTextReaderRead') {*}
    method readAttributeValue(--> int32) is native($XML2) is symbol('xmlTextReaderReadAttributeValue') {*}
    method readInnerXml(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderReadInnerXml') {*}
    method readOuterXml(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderReadOuterXml') {*}
    method readState(--> int32) is native($XML2) is symbol('xmlTextReaderReadState') {*}
    method setRelaxNGSchema(xmlRelaxNG --> int32) is native($XML2) is symbol('xmlTextReaderRelaxNGSetSchema') {*}
    method setRelaxNGFile(Str --> int32) is native($XML2) is symbol('xmlTextReaderRelaxNGValidate') {*}
    method setXsdSchema(xmlSchema --> int32) is native($XML2) is symbol('xmlTextReaderSetSchema') {*}
    method setXsdFile(Str --> int32) is native($XML2) is symbol('xmlTextReaderSchemaValidate') {*}
    method setStructuredErrorFunc( &error-func (Pointer $, xmlError $)) is native($XML2) is symbol('xmlTextReaderSetStructuredErrorHandler') {*};
    method skipSiblings(--> int32) is native($BIND-XML2) is symbol('xml6_reader_skip_siblings') {*}
    method standalone(--> int32) is native($XML2) is symbol('xmlTextReaderStandalone') {*}
    method value(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstValue') {*}
    method xmlLang(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstXmlLang') {*}
    method xmlVersion(--> xmlCharP) is native($XML2) is symbol('xmlTextReaderConstXmlVersion') {*}
    method Setup(xmlParserInputBuffer, Str $uri, Str $enc, int32 $opts --> int32) is symbol('xmlTextReaderSetup') is native($XML2) {*}
    method Free is symbol('xmlFreeTextReader') is native($XML2) {*}

    multi method new(Blob :$buf!, UInt :$len = $buf.bytes, xmlEncodingStr :$enc, Str :$URI, UInt :$flags = 0) {
        NewMemory($buf, $len, $URI, $enc, $flags);
    }
    multi method new(UInt:D :$fd!, Str :$URI, xmlEncodingStr :$enc, UInt :$flags = 0) {
        NewFd( $fd, $URI, $enc, $flags);
    }
    multi method new(Str:D :$file!, xmlEncodingStr :$enc, UInt :$flags = 0) {
        NewFile( $file, $enc, $flags);
    }
    multi method new(xmlDoc:D :$doc!) {
        NewDoc( $doc);
    }

    multi method new(|c) is default { fail c.raku }
}

