use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::SAX::Handler::SAX2;

    submethod TWEAK {
        self.sax-handler //= LibXML::SAX::Handler::SAX2;
    }

}
