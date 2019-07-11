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
    use LibXML::Pattern;
    use LibXML::RelaxNG;
    use LibXML::Schema;
    use LibXML::_Options;

    has xmlTextReader $.native handles<
        attributeCount baseURI byteConsumed columnNumber depth
        encoding getAttribute getAttributeNo getAttributeNs
        lineNumber localName lookupNamespace name namespaceURI
        nodeType prefix readAttributeValue readInnerXml readOuterXml
        value readState standalone xmlLang xmlVersion
    >;
    has xmlEncodingStr $!enc;
    method enc { $!enc }
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;
    has Blob $!buf;
    my subset RelaxNG where {!.defined || $_ ~~ LibXML::RelaxNG|Str};
    my subset Schema  where {!.defined || $_ ~~ LibXML::Schema|Str};
    has RelaxNG $!RelaxNG;
    has Schema  $!Schema;

    # Perl 5 compat
    also does LibXML::_Options[
        %(
            :complete-attributes(XML_PARSER_DEFAULTATTRS),
            :expand-entities(XML_PARSER_SUBST_ENTITIES),
            :load-ext-dtd(XML_PARSER_LOADDTD),
            :recover(XML_PARSE_RECOVER),
            :suppress-errors(XML_PARSE_NOERROR),
            :validation(XML_PARSER_VALIDATE),
        )];
    multi method recover is rw {
        Proxy.new(
            FETCH => { 
                my $recover = $.get-flag($!flags, 'recover');
                $recover && $.get-flag($!flags, 'suppress-errors') ?? 2 !! $recover;
            },
            STORE => -> $, UInt() $v {
                $!errors.recover = $v >= 1;
                $.set-flag($!flags, 'recover', $v >= 1);
                $.set-flag($!flags, 'suppress-errors', $v >= 2);
            }
        );
    }
    multi method recover($v) { $.recover = $v }

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
            hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid
            moveToAttribute moveToAttributeNo moveToElement moveToFirstAttribute moveToNextAttribute next
            nextSibling read skipSiblings
         > {
            $?CLASS.^add_method( $_, method (|c) { self!try-bool($_, |c) });
        }

    }

    has UInt $.flags is rw = 0;
    has LibXML::Document $!document;
    method document {
        $!document //= LibXML::Document.new: :native($_)
            with $!native.currentDoc;
    }

    multi submethod TWEAK( xmlTextReader:D :$!native! ) {
    }
    multi submethod TWEAK(LibXML::Document:D :DOM($!document)!,
                          RelaxNG :$!RelaxNG, Schema :$!Schema,
                         ) {
        my xmlDoc:D $doc = $!document.native;
        $!native .= new: :$doc;
        self!setup: :!errors;
    }
    method !init-flags(%opts) {
        self.set-flags($!flags, :expand-entities, |%opts);
    }
    multi submethod TWEAK(Blob:D :$!buf!, UInt :$len = $!buf.bytes,
                          Str :$URI, RelaxNG :$!RelaxNG, Schema :$!Schema,
                          :$!enc, *%opts) {
        self!init-flags(%opts);
        $!native .= new: :$!buf, :$len, :$!enc, :$URI, :$!flags;
        self!setup;
    }
    multi submethod TWEAK(Str:D :$string!, xmlEncodingStr :$!enc = 'UTF-8', |c) {
        my $buf = $string.encode($!enc);
        self.TWEAK( :$buf, :$!enc, |c);
    }
    multi submethod TWEAK(UInt:D :$fd!, Str :$URI,
                          RelaxNG :$!RelaxNG, Schema :$!Schema,
                          xmlEncodingStr :$!enc, *%opts) {
        self!init-flags(%opts);
        $!native .= new: :$fd, :$!enc, :$URI, :$!flags;
        self!setup;
    }
    multi submethod TWEAK(IO::Handle:D :$io!, :$URI = $io.path.path, |c) {
        $io.open(:r) unless $io.opened;
        my UInt:D $fd = $io.native-descriptor;
        self.TWEAK( :$fd, :$URI, |c );
    }
    multi submethod TWEAK(Str:D :$URI!, |c) {
        my IO::Handle:D $io = $URI.IO.open(:r);
        my UInt:D $fd = $io.native-descriptor;
        self.TWEAK: :$fd, :$URI, |c;
    }
    multi submethod TWEAK(Str:D :location($URI)!, |c) {
        self.TWEAK: :$URI, |c;
    }

    method !setup(Bool :$errors = True) {
        my Pair $call;
        if $errors {
            $!native.setStructuredErrorFunc: -> Pointer $ctx, xmlError:D $err {
                self.structured-error($err);
            }
        }
        with $!RelaxNG {
            when Str { $call := :setRelaxNGFile($_); }
            default  { $call := :setRelaxNGSchema(.native) }
        }
        with $!Schema {
            when Str { $call := :setXsdFile($_); }
            default  { $call := :setXsdSchema(.native) }
        }
        self!try-bool(.key, .value) with $call;
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

    method nextPatternMatch(LibXML::Pattern:D $pattern) {
        self!try-bool('nextPatternMatch', $pattern.native);
    }

    method nextSiblingElement(QName $name?, Str $URI?) {
        self!try-bool('nextSiblingElement', $name, $URI);
    }

    method preservePattern(Str:D $pattern, :%ns) {
        $.document; # realise containing document
        my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
        self!try('preservePattern', $pattern, $ns);
    }

    method matchesPattern(LibXML::Pattern:D $pattern) {
        $pattern.matchesNode($_) with $!native.currentNode;
    }

    method nodePath {
        .GetNodePath with $!native.currentNode;
    }

    method preserveNode(Bool :$deep) {
        $.document; # realise containing document
        my domNode $node = self!try('preserveNode');
        LibXML::Node.box($node);
    }

    method close(--> Bool) {
        my $rv := ! self!try-bool('close');
        $!buf = Nil;
        $rv;
    }

    method finish(--> Bool) {
        my $rv := self!try-bool('finish');
        $!buf = Nil;
        $rv;
    }

    method have-reader {
        ? xml6_gbl_have_libxml_reader();
    }

    method FALLBACK($key, |c) is rw {
        $.option-exists($key)
        ?? $.option($key, |c)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }
}
