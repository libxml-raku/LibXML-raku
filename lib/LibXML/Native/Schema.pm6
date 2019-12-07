unit module LibXML::Native::Schema;

use NativeCall;
use LibXML::Native;
use LibXML::Native::Defs :$XML2, :Opaque;

class xmlSchema is repr(Opaque) is export {
   method Free is symbol('xmlSchemaFree') is native($XML2) {*}
}

class xmlSchemaParserCtxt is repr(Opaque) is export {
    our sub NewUrl(Str:D --> xmlSchemaParserCtxt) is native($XML2) is symbol('xmlSchemaNewParserCtxt') {*}
    our sub NewMemory(Blob:D, int32 --> xmlSchemaParserCtxt) is native($XML2) is symbol('xmlSchemaNewMemParserCtxt') {*}
    our sub NewDoc(xmlDoc:D --> xmlSchemaParserCtxt) is native($XML2) is symbol('xmlSchemaNewDocParserCtxt') {*}
    method SetGenericErrorFunc( &err-func (xmlSchemaParserCtxt $ctx1, Str $msg1, Pointer), &warn-func (xmlSchemaParserCtxt $ctx2, Str $msg2, Pointer), Pointer $ctx) is native($XML2) is symbol('xmlSchemaSetParserErrors') {*}
    method SetParserErrorFunc( &error-func (xmlSchemaParserCtxt $, xmlError $)) is native($XML2) is symbol('xmlSchemaSetParserStructuredErrors') {*};
    method SetStructuredErrorFunc( &error-func (xmlValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method Parse(-->xmlSchema) is native($XML2) is symbol('xmlSchemaParse') {*}
    method Free is symbol('xmlSchemaFreeParserCtxt') is native($XML2) {*}
    multi method new(Str:D :$url) {
        NewUrl($url);
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlSchemaParserCtxt:D) {
        NewMemory($buf, $bytes);
    }
    multi method new(xmlDoc:D :$doc!) {
        NewDoc($doc);
    }
}

class xmlSchemaValidCtxt is repr(Opaque) is export {
    our sub New(xmlSchema:D --> xmlSchemaValidCtxt) is native($XML2) is symbol('xmlSchemaNewValidCtxt') {*}
    method SetStructuredErrorFunc( &error-func (xmlSchemaValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlSchemaSetValidStructuredErrors') {*};
    method ValidateDoc(xmlDoc:D --> int32) is native($XML2) is symbol('xmlSchemaValidateDoc') {*}
    method ValidateElement(xmlNode:D --> int32) is native($XML2) is symbol('xmlSchemaValidateOneElement') {*}
    method Free is symbol('xmlSchemaFreeValidCtxt') is native($XML2) {*}
    method new(xmlSchema:D :$schema!) {
        New($schema);
    }
}
