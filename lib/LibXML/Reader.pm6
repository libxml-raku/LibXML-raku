use v6;

unit class LibXML::Reader;

use NativeCall;
use LibXML::Enums;
use LibXML::Native;
use LibXML::Native::TextReader;
has xmlTextReader $!native handles<attributeCount baseURI byteConsumed columnNumber depth encoding getAttribute getAttributeNo getAttributeNs hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid lineNumber localName lookupNamespace movetoAttribute movetoAttributeNo movetoAttributeNs moveToElement moveToFirstAttribute moveToNextAttribute name namespaceURI prefix readAttributeValue value xmlLang xmlVersion>;
use LibXML::_Options;
has  UInt $.flags is rw;

also does LibXML::_Options[
    %(
        :load-ext-dtd(XML_PARSER_LOADDTD),
        :complete-attributes(XML_PARSER_DEFAULTATTRS),
        :validation(XML_PARSER_VALIDATE),
        :expand-entities(XML_PARSER_SUBST_ENTITIES),
    )];

multi submethod BUILD( xmlTextReader:D :$!native! ) {
}
multi submethod BUILD(Str:D :$url!) {
    $!native .= new: :$url;
}
multi submethod BUILD(Str:D :location($url)!) {
    self.BUILD: :$url;
}

submethod TWEAK(*%opts) {
    self.set-flags($!flags, %opts);
    $!native.setup(:$!flags )
}

submethod DESTROY {
    .Free with $!native;
}

method have-reader {
    ? xml6_gbl_have_libxml_reader();
}

method get-option(Str:D $key) { $.get-flag($!flags, $key); }
method set-option(Str:D $key, Bool() $_) { $.set-flag($!flags, $key, $_); }

method read {$!native.Read}

method FALLBACK($key, |c) is rw {
    $.is-option($key)
    ?? $.option($key)
    !! X::Method::NotFound.new( :method($key), :typename(self.^name) );
}
