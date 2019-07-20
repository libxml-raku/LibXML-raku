unit module LibXML::Native::Schema;

use NativeCall;
use LibXML::Native;

constant Stub = LibXML::Native::Stub;
constant LIB  = LibXML::Native::LIB;

class xmlSchema is repr(Stub) is export {
   method Free is symbol('xmlSchemaFree') is native(LIB) {*}
}

class xmlSchemaParserCtxt is repr(Stub) is export {
    sub xmlSchemaNewParserCtxt(Str:D --> xmlSchemaParserCtxt) is native(LIB) {*}
    sub xmlSchemaNewMemParserCtxt(Blob:D, int32 --> xmlSchemaParserCtxt) is native(LIB) {*}
    sub xmlSchemaNewDocParserCtxt(xmlDoc:D --> xmlSchemaParserCtxt) is native(LIB) {*}
    method SetGenericErrorFunc( &err-func (xmlSchemaParserCtxt $ctx1, Str $msg1, Pointer), &warn-func (xmlSchemaParserCtxt $ctx2, Str $msg2, Pointer), Pointer $ctx) is native(LIB) is symbol('xmlSchemaSetParserErrors') {*}
    method SetStructuredErrorFunc( &error-func (xmlSchemaParserCtxt $, xmlError $)) is native(LIB) is symbol('xmlSchemaSetParserStructuredErrors') {*};
    method Parse(-->xmlSchema) is native(LIB) is symbol('xmlSchemaParse') {*}
    method Free is symbol('xmlSchemaFreeParserCtxt') is native(LIB) {*}
    multi method new(Str:D :$url) {
        xmlSchemaNewParserCtxt($url);
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlSchemaParserCtxt:D) {
         xmlSchemaNewMemParserCtxt($buf, $bytes);
    }
    multi method new(xmlDoc:D :$doc!) {
        xmlSchemaNewDocParserCtxt($doc);
    }
}

class xmlSchemaValidCtxt is repr(Stub) is export {
    sub xmlSchemaNewValidCtxt(xmlSchema:D --> xmlSchemaValidCtxt) is native(LIB) {*}
    method SetStructuredErrorFunc( &error-func (xmlSchemaValidCtxt $, xmlError $)) is native(LIB) is symbol('xmlSchemaSetValidStructuredErrors') {*};
    method ValidateDoc(xmlDoc:D --> int32) is native(LIB) is symbol('xmlSchemaValidateDoc') {*}
    method ValidateElement(xmlNode:D --> int32) is native(LIB) is symbol('xmlSchemaValidateOneElement') {*}
    method Free is symbol('xmlSchemaFreeValidCtxt') is native(LIB) {*}
    method new(xmlSchema:D :$schema!) {
        xmlSchemaNewValidCtxt($schema);
    }
}
