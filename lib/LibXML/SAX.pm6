use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::SAX::Handler;
    has LibXML::SAX::Handler $.sax-handler is required;

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
}
