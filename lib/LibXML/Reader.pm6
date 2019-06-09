use v6;

class X::LibXML::Reader::OpFail is Exception {
    has Str:D $.op is required;
    method message { "XML Read $!op operation failed" }
}

class LibXML::Reader {

    use NativeCall;
    use LibXML::Enums;
    use LibXML::Native;
    use LibXML::Native::TextReader;
    use LibXML::Types :QName;

    has xmlTextReader $!native handles<attributeCount baseURI byteConsumed columnNumber depth encoding getAttribute getAttributeNo getAttributeNs lineNumber localName lookupNamespace name namespaceURI nodeType prefix readAttributeValue readInnerXml readOuterXml value readState standalone xmlLang xmlVersion>;

    method !try-bool(Str:D $op, |c) {
        my $rv := $!native."$op"(|c);
        fail X::LibXML::Reader::OpFail.new(:$op)
            if $rv < 0;
        $rv > 0;
    }

    INIT {
        for <hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid moveToAttribute moveToAttributeNo moveToElement moveToFirstAttribute moveToNextAttribute nextSibling read> {
            $?CLASS.^add_method( $_, method (|c) { self!try-bool($_, |c) });
        }

    }

    has  UInt $.flags is rw;

    use LibXML::_Options;
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

    multi method getParserProp(Str:D $opt) {
        $!native.getParserProp: self.get-option($opt);
    }

    multi method getParserProp(Numeric:D $opt) {
        $!native.getParserProp: $opt;
    }

    method moveToAttributeNs(QName:D $name, Str $uri) {
        $uri
        ?? self!try-bool('moveToAttributeNs', $name, $uri)
        !! self!try-bool('moveToAttribute', $name );
    }

    method close(--> Bool) {
        my $rv :=  $!native.close;
        fail X::LibXML::Reader::OpFail: :op<close>
          if $rv < 0;
        $rv == 0;
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

    method FALLBACK($key, |c) is rw {
        $.is-option($key)
        ?? $.option($key)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }
}
