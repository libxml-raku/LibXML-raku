use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::Native;
    use LibXML::SAX::Handler;
    use LibXML::SAX::Handler::SAX2;
    has LibXML::SAX::Handler $.sax-handler = LibXML::SAX::Handler::SAX2;

    use LibXML::Native;
    use LibXML::Document;
    use LibXML::DocumentFragment;

    method parse(|c) {
        my LibXML::Document $doc = callsame;
        $!sax-handler.finish: :$doc;
    }

    method finish-push(|c) {
        my LibXML::Document $doc = callsame;
        $!sax-handler.finish: :$doc;
    }

    method parse-balanced(|c) {
        my LibXML::DocumentFragment $doc = callsame;
        $!sax-handler.finish: :$doc;
    }

    method reparse(LibXML::Document:D $doc!, |c) {
        # document DOM with the SAX handler
        my $string = $doc.Str;
        $.parse( :$string, |c );
    }
    method generate(LibXML::Document:D :$doc, |c) is DEPRECATED("use 'reparse' method") {
        $.reparse($doc, |c);
    }
}
