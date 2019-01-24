
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Native;
    has xmlSAXHandler $.sax;
    method sax {
        $!sax //= LibXML::SAX::Builder.build(self);
    }
}

