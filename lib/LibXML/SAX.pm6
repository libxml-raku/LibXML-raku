use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::Native;
    use LibXML::SAX::Handler;
    use LibXML::SAX::Handler::SAX2;
    use Method::Also;
    use LibXML::Native;
    use LibXML::Document;
    use LibXML::DocumentFragment;

    has LibXML::SAX::Handler $.sax-handler is rw = LibXML::SAX::Handler::SAX2;

    method parse(|c) {
        my LibXML::Document $doc = callsame;
        $!sax-handler.publish: :$doc;
    }

    method finish-push(|c) {
        my LibXML::Document $doc = callsame;
        $!sax-handler.publish: :$doc;
    }

    method parse-balanced(|c) {
        my LibXML::DocumentFragment $doc = callsame;
        $!sax-handler.publish: :$doc;
    }

    method reparse(LibXML::Document:D $doc!, |c) is also<generate> {
        # document DOM with the SAX handler
        my $string = $doc.Str;
        $.parse( :$string, |c );
    }
}
