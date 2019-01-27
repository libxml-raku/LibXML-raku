# a base class that provides a full set of SAX2 callbacks
# commonly used as a base class
use LibXML::SAX::Handler;
class LibXML::SAX::Handler::SAX2
    is LibXML::SAX::Handler {
    use LibXML::Native;
    use NativeCall;
    use LibXML::SAX::Handler::SAX2::Locator;
    has LibXML::SAX::Handler::SAX2::Locator $.locator .= new;
    use LibXML::Document;
    method finish-doc(LibXML::Document :$doc!) {
        $doc;
    }

    constant LIB = LibXML::Native::LIB;
    constant Ctx = parserCtxt;

    method setDocumentLocator(xmlSAXLocator $loc, :$ctx!) {
        warn "i'm setting up a document locator, wish me luck!!";
        use LibXML::SAX::Builder;
        LibXML::SAX::Builder.build-locator($.locator, $loc);

        $ctx.xmlSAX2SetDocumentLocator($loc);
    }

    method isStandalone(:$ctx!) returns Bool {
        ? $ctx.xmlSAX2IsStandalone;
    }

    method startElement(Str $name, CArray :$atts!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElement($name, $atts);
    }

    method endElement(Str $name, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElement($name);
    }

    method characters(Str $chars, Ctx :$ctx!) {
        my Blob $buf = $chars.encode;
        $ctx.xmlSAX2Characters($buf, +$buf);
    }

    method getEntity(Str $name, Ctx :$ctx!) {
        $ctx.xmlSAX2GetEntity($name);
    }
}
