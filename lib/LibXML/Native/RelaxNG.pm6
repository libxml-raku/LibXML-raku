unit module LibXML::Native::RelaxNG;

use NativeCall;
use LibXML::Native;
use LibXML::Native::Defs :XML2, :Opaque;

class xmlRelaxNG is repr(Opaque) is export {
    method Free is symbol('xmlRelaxNGFree') is native(XML2) {*}
}

class xmlRelaxNGParserCtxt is repr(Opaque) is export {
    sub xmlRelaxNGNewParserCtxt(Str:D --> xmlRelaxNGParserCtxt) is native(XML2) {*}
    sub xmlRelaxNGNewMemParserCtxt(Blob:D, int32 --> xmlRelaxNGParserCtxt) is native(XML2) {*}
    sub xmlRelaxNGNewDocParserCtxt(xmlDoc:D --> xmlRelaxNGParserCtxt) is native(XML2) {*}
    method SetGenericErrorFunc( &err-func (xmlRelaxNGParserCtxt $ctx1, Str $msg1, Pointer), &warn-func (xmlRelaxNGParserCtxt $ctx2, Str $msg2, Pointer), Pointer $ctx) is native(XML2) is symbol('xmlRelaxNGSetParserErrors') {*}
    method SetStructuredErrorFunc( &error-func (xmlRelaxNGParserCtxt $, xmlError $)) is native(XML2) is symbol('xmlRelaxNGSetParserStructuredErrors') {*};
    method Parse(-->xmlRelaxNG) is native(XML2) is symbol('xmlRelaxNGParse') {*}
    method Free is symbol('xmlRelaxNGFreeParserCtxt') is native(XML2) {*}
    multi method new(Str:D :$url) {
        xmlRelaxNGNewParserCtxt($url);
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlRelaxNGParserCtxt:D) {
         xmlRelaxNGNewMemParserCtxt($buf, $bytes);
    }
    multi method new(xmlDoc:D :$doc!) {
        xmlRelaxNGNewDocParserCtxt($doc);
    }
}

class xmlRelaxNGValidCtxt is repr(Opaque) is export {
    sub xmlRelaxNGNewValidCtxt(xmlRelaxNG:D --> xmlRelaxNGValidCtxt) is native(XML2) {*}
    method SetStructuredErrorFunc( &error-func (xmlRelaxNGValidCtxt $, xmlError $)) is native(XML2) is symbol('xmlRelaxNGSetValidStructuredErrors') {*};
    method ValidateDoc(xmlDoc:D --> int32) is native(XML2) is symbol('xmlRelaxNGValidateDoc') {*}
    method Free is symbol('xmlRelaxNGFreeValidCtxt') is native(XML2) {*}
    method new(xmlRelaxNG:D :$schema!) {
        xmlRelaxNGNewValidCtxt($schema);
    }
}
