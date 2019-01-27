use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::SAX::Handler;
    has LibXML::SAX::Handler $.handler is required;

    use LibXML::Native;

    submethod TWEAK {
        self.sax = .sax given $!handler;
    }

    method parse(|c) {
        my $doc = callsame;
        $!handler.finish-doc: :$doc;
    }

    method finish-push(|c) {
        my $doc = callsame;
        $!handler.finish-doc: :$doc;
    }
}
