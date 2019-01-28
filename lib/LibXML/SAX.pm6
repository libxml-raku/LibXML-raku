use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::SAX::Handler;
    has LibXML::SAX::Handler $.handler is required;

    use LibXML::Native;
    use LibXML::Document;
    use LibXML::DocumentFragment;

    submethod TWEAK {
        self.sax = .sax given $!handler;
    }

    method parse(|c) {
        my LibXML::Document $doc = callsame;
        $!handler.finish: :$doc;
    }

    method finish-push(|c) {
        my LibXML::Document $doc = callsame;
        $!handler.finish: :$doc;
    }

    method parse-balanced(|c) {
        my LibXML::DocumentFragment $doc = callsame;
        $!handler.finish: :$doc;
    }
}
