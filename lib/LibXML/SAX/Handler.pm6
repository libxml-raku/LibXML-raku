
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Native;
    has xmlSAXHandler $!sax;
    submethod TWEAK(xmlSAXHandler :$!sax) { }
    method unbox {
        $!sax //= LibXML::SAX::Builder.build-sax(self);
    }
}

