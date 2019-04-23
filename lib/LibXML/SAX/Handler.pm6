
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Native;
    has xmlSAXHandler $!struct;
    has $.sax-builder = LibXML::SAX::Builder;
    submethod TWEAK(xmlSAXHandler :$!struct) { }
    method unbox {
        $!struct //= $!sax-builder.build-sax-handler(self);
    }
}

