unit module LibXML::Native::TextReader;

use NativeCall;
use LibXML::Native;

constant Stub = LibXML::Native::Stub;
constant LIB  = LibXML::Native::LIB;
constant BIND-LIB = LibXML::Native::BIND-LIB;

sub xml6_gbl_have_libxml_reader(--> int32) is native(BIND-LIB) is export {*}

class xmlTextReader is repr('CPointer') is export {

    sub xmlNewTextReader(Blob, Str --> xmlTextReader) is native(LIB) {*}

    sub xmlNewTextReaderFilename(Str --> xmlTextReader) is native(LIB) {*}

    method Read(--> int32) is native(LIB) is symbol('xmlTextReaderRead') {*}
    method ByteConsumed(--> ulong) is native(LIB) is symbol('xmlTextReaderByteConsumed') {*}
    method Setup(xmlParserInputBuffer, Str $uri, Str $enc, int32 $opts --> int32) is symbol('xmlTextReaderSetup') is native(LIB) {*}
    method Free is symbol('xmlFreeTextReader') is native(LIB) {*}
    method setup(xmlParserInputBuffer :$buf, Str :$uri, xmlEncodingStr :$enc, UInt :$flags = 0) {
        $.Setup($buf, $uri, $enc, $flags);
    }

    multi method new(Blob:D :$buf!, Str :$url) {
        xmlNewTextReader($buf, $url);
    }
    multi method new(Str:D :$url) {
        xmlNewTextReaderFilename($url);
    }
    multi method new(|) is default { fail }
}

