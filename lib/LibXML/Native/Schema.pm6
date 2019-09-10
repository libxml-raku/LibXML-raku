unit module LibXML::Native::Schema;

use NativeCall;
use LibXML::Native;
use LibXML::Native::Defs :XML2, :Opaque;

class xmlSchema is repr(Opaque) is export {
   method Free is symbol('xmlSchemaFree') is native(XML2) {*}
}

class xmlSchemaParserCtxt is repr(Opaque) is export {
    sub xmlSchemaNewParserCtxt(Str:D --> xmlSchemaParserCtxt) is native(XML2) {*}
    sub xmlSchemaNewMemParserCtxt(Blob:D, int32 --> xmlSchemaParserCtxt) is native(XML2) {*}
    sub xmlSchemaNewDocParserCtxt(xmlDoc:D --> xmlSchemaParserCtxt) is native(XML2) {*}
    method SetGenericErrorFunc( &err-func (xmlSchemaParserCtxt $ctx1, Str $msg1, Pointer), &warn-func (xmlSchemaParserCtxt $ctx2, Str $msg2, Pointer), Pointer $ctx) is native(XML2) is symbol('xmlSchemaSetParserErrors') {*}
    method SetStructuredErrorFunc( &error-func (xmlSchemaParserCtxt $, xmlError $)) is native(XML2) is symbol('xmlSchemaSetParserStructuredErrors') {*};
    method Parse(-->xmlSchema) is native(XML2) is symbol('xmlSchemaParse') {*}
    method Free is symbol('xmlSchemaFreeParserCtxt') is native(XML2) {*}
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

class xmlSchemaValidCtxt is repr(Opaque) is export {
    sub xmlSchemaNewValidCtxt(xmlSchema:D --> xmlSchemaValidCtxt) is native(XML2) {*}
    method SetStructuredErrorFunc( &error-func (xmlSchemaValidCtxt $, xmlError $)) is native(XML2) is symbol('xmlSchemaSetValidStructuredErrors') {*};
    method ValidateDoc(xmlDoc:D --> int32) is native(XML2) is symbol('xmlSchemaValidateDoc') {*}
    method ValidateElement(xmlNode:D --> int32) is native(XML2) is symbol('xmlSchemaValidateOneElement') {*}
    method Free is symbol('xmlSchemaFreeValidCtxt') is native(XML2) {*}
    method new(xmlSchema:D :$schema!) {
        xmlSchemaNewValidCtxt($schema);
    }
}
