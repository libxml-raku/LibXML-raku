
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Native;
    has xmlSAXHandler $.native;
    has $.sax-builder = LibXML::SAX::Builder;
    method native {
        $!native //= $!sax-builder.build-sax-handler(self);
    }
}

