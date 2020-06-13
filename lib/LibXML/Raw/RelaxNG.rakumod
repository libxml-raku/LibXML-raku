unit module LibXML::Raw::RelaxNG;

use NativeCall;
use LibXML::Raw;
use LibXML::Raw::Defs :$XML2, :Opaque;

class xmlRelaxNG is repr(Opaque) is export {
    method Free is symbol('xmlRelaxNGFree') is native($XML2) {*}
}

class xmlRelaxNGParserCtxt is repr(Opaque) is export {
    our sub NewUrl(Str:D --> xmlRelaxNGParserCtxt) is native($XML2) is symbol('xmlRelaxNGNewParserCtxt') {*}
    our sub NewMemory(Blob:D, int32 --> xmlRelaxNGParserCtxt) is native($XML2) is symbol('xmlRelaxNGNewMemParserCtxt') {*}
    our sub NewDoc(xmlDoc:D --> xmlRelaxNGParserCtxt) is native($XML2) is symbol('xmlRelaxNGNewDocParserCtxt') {*}
    method SetGenericErrorFunc( &err-func (xmlRelaxNGParserCtxt $ctx1, Str $msg1, Pointer), &warn-func (xmlRelaxNGParserCtxt $ctx2, Str $msg2, Pointer), Pointer $ctx) is native($XML2) is symbol('xmlRelaxNGSetParserErrors') {*}
    method SetParserErrorFunc( &error-func (xmlRelaxNGParserCtxt $, xmlError $)) is native($XML2) is symbol('xmlRelaxNGSetParserStructuredErrors') {*};
     method SetStructuredErrorFunc( &error-func (xmlValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method Parse(-->xmlRelaxNG) is native($XML2) is symbol('xmlRelaxNGParse') {*}
    method Free is symbol('xmlRelaxNGFreeParserCtxt') is native($XML2) {*}
    multi method new(Str:D :$url) {
        NewUrl($url);
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlRelaxNGParserCtxt:D) {
        NewMemory($buf, $bytes);
    }
    multi method new(xmlDoc:D :$doc!) {
        NewDoc($doc);
    }
}

class xmlRelaxNGValidCtxt is repr(Opaque) is export {
    our sub New(xmlRelaxNG:D --> xmlRelaxNGValidCtxt) is native($XML2) is symbol('xmlRelaxNGNewValidCtxt') {*}
    method SetStructuredErrorFunc( &error-func (xmlRelaxNGValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlRelaxNGSetValidStructuredErrors') {*};
    method ValidateDoc(xmlDoc:D --> int32) is native($XML2) is symbol('xmlRelaxNGValidateDoc') {*}
    method Free is symbol('xmlRelaxNGFreeValidCtxt') is native($XML2) {*}
    method new(xmlRelaxNG:D :$schema!) {
        New($schema);
    }
}
