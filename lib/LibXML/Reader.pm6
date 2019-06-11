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
    use LibXML::Document;

    has xmlTextReader $!native handles<attributeCount baseURI byteConsumed columnNumber depth encoding getAttribute getAttributeNo getAttributeNs lineNumber localName lookupNamespace name namespaceURI nodeType prefix readAttributeValue readInnerXml readOuterXml value readState standalone xmlLang xmlVersion>;

    method !try-bool(Str:D $op, |c) {
        my $rv := $!native."$op"(|c);
        fail X::LibXML::Reader::OpFail.new(:$op)
            if $rv < 0;
        $rv > 0;
    }

    INIT {
        for <hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid moveToAttribute moveToAttributeNo moveToElement moveToFirstAttribute moveToNextAttribute next nextSibling read skipSiblings> {
            $?CLASS.^add_method( $_, method (|c) { self!try-bool($_, |c) });
        }

    }

    has UInt $.flags is rw;
    has LibXML::Document $.document;
    method document {
        with $!document {
            $_;
        }
        else {
            with $!native.currentDoc -> $struct {
                $!document .= new: :$struct;
            }
            else {
                LibXML::Document;
            }
        }
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
    multi submethod BUILD(Str:D :$URI!, |c) {
        $!native .= new: :$URI, |c;
    }
    multi submethod BUILD(Str:D :location($URI)!, |c) {
        self.BUILD: :$URI, |c;
    }
    multi submethod BUILD(UInt:D :$fd!, |c) {
        $!native .= new: :$fd, |c;
    }
    multi submethod BUILD(Str:D :$string!, Str :$URI, xmlEncodingStr :$enc, |c) {
        $!native .= new: :$string, :$enc, :$URI;
    }
    multi submethod BUILD(LibXML::Document:D :DOM($!document)!) {
        $!native .= new: :doc($!document.native);
    }
    multi submethod BUILD(IO::Handle:D :$io!, :$URI = $io.path.path, |c) {
        my UInt:D $fd = $io.native-descriptor;
        self.BUILD( :$fd, :$URI, |c );
    }

    multi submethod TWEAK(:DOM($)!) {}
    multi submethod TWEAK(:location($), :URI($), :fd($), :string($), :io($), *%opts) is default {
        self.set-flags($!flags, %opts);
        $!native.setup(:$!flags )
    }

    submethod DESTROY {
        .Free with $!native;
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
        my CArray[Str] $ns .= new: |(%ns.kv), Str;
        $!native.preservePattern($pattern, $ns);
    }

    method copyCurrentNode(Bool :$deep) {
        my domNode $node = $deep
            ?? $!native.currentNodeTree
            !! $!native.currentNode;
        $node .= copy: :$deep;
        LibXML::Node.box($node, :doc($.document));
    }

    method close(--> Bool) {
        my $rv :=  $!native.close;
        fail X::LibXML::Reader::OpFail: :op<close>
          if $rv < 0;
        $rv == 0;
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
