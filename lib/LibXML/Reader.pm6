use v6;

class X::LibXML::Reader::OpFail is Exception {
    has Str:D $.op is required;
    method message { "XML Read $!op operation failed" }
}

class LibXML::Reader {

    use NativeCall;
    use LibXML::Enums;
    use LibXML::ErrorHandler;
    use LibXML::Native;
    use LibXML::Native::TextReader;
    use LibXML::Types :QName;
    use LibXML::Document;

    has xmlTextReader $.native handles<
        attributeCount baseURI byteConsumed columnNumber depth
        encoding getAttribute getAttributeNo getAttributeNs
        lineNumber localName lookupNamespace name namespaceURI
        nodeType prefix readAttributeValue readInnerXml readOuterXml
        value readState standalone xmlLang xmlVersion
    >;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    method !try(Str:D $op, |c) {
        my $rv := $!native."$op"(|c);
        self.flush-errors;
        $rv;
    }

    method !try-bool(Str:D $op, |c) {
        my $rv := self!try($op, |c);
        fail X::LibXML::Reader::OpFail.new(:$op)
            if $rv < 0;
        $rv > 0;
    }

    INIT {
        for <
            finish hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid
            moveToAttribute moveToAttributeNo moveToElement moveToFirstAttribute moveToNextAttribute next
            nextSibling read skipSiblings
         > {
            $?CLASS.^add_method( $_, method (|c) { self!try-bool($_, |c) });
        }

    }

    has UInt $.flags is rw;
    has LibXML::Document $!document;
    method document {
        $!document //= LibXML::Document.new: :native($_)
            with $!native.currentDoc;
        $!document;
    }

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
    multi submethod BUILD(Str:D :$string!, Str :$URI, xmlEncodingStr :$enc, |c) {
        $!native .= new: :$string, :$enc, :$URI;
    }
    multi submethod BUILD(Str:D :$URI!, |c) {
        $!native .= new: :$URI, |c;
    }
    multi submethod BUILD(Str:D :location($URI)!, |c) {
        self.BUILD: :$URI, |c;
    }
    multi submethod BUILD(UInt:D :$fd!, |c) {
        $!native .= new: :$fd, |c;
    }
    multi submethod BUILD(LibXML::Document:D :DOM($!document)!) {
        my xmlDoc:D $doc = $!document.native;
        $!native .= new: :$doc;
    }
    multi submethod BUILD(IO::Handle:D :$io!, :$URI = $io.path.path, |c) {
        my UInt:D $fd = $io.native-descriptor;
        self.BUILD( :$fd, :$URI, |c );
    }

    multi submethod TWEAK(:DOM($)!) {}
    multi submethod TWEAK(:location($), :URI($), :fd($), :string($), :io($), *%opts) is default {
        self.set-flags($!flags, %opts);
        with $!native {
            .setup(:$!flags );
            .setStructuredErrorFunc: -> Pointer $ctx, xmlError:D $err {
                self.structured-error($err);
            }
        }
    }

    submethod DESTROY {
        .Free with $!native;
    }

    method copyCurrentNode(Bool :$deep) {
        my domNode $node = self!try(
            $deep ?? 'currentNodeTree' !! 'currentNode'
        );
        $node .= copy: :$deep;
        LibXML::Node.box($node);
    }

    multi method getParserProp(Str:D $opt) {
        $!native.getParserProp: self.get-option($opt);
    }

    multi method getParserProp(Numeric:D $opt) {
        $!native.getParserProp: $opt;
    }

    method moveToAttributeNs(QName:D $name, Str $URI) {
        $URI
        ?? self!try-bool('moveToAttributeNs', $name, $URI)
        !! self!try-bool('moveToAttribute', $name );
    }

    method nextElement(QName $name?, Str $URI?) {
        self!try-bool('nextElement', $name, $URI);
    }

    method nextSiblingElement(QName $name?, Str $URI?) {
        self!try-bool('nextSiblingElement', $name, $URI);
    }

    method preservePattern(Str:D $pattern, *%ns) {
        $.document; # realise containing document
        my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
        self!try('preservePattern', $pattern, $ns);
    }

    method preserveNode(Bool :$deep) {
        $.document; # realise containing document
        my domNode $node = self!try('preserveNode');
        LibXML::Node.box($node);
    }

    method close(--> Bool) {
        ! self!try-bool('close');
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
