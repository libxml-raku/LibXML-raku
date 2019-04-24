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
    use LibXML::DocumentFragment;
    use LibXML::Types :QName, :NCName;

    multi method finish(LibXML::Document :$doc!) {
        $doc;
    }
    multi method finish(LibXML::DocumentFragment :$doc!) {
        $doc;
    }

    constant Ctx = parserCtxt;

    method setDocumentLocator(xmlSAXLocator $loc, :$ctx!) {
        use LibXML::SAX::Builder;
        LibXML::SAX::Builder.build-locator($.locator, $loc);

        $ctx.xmlSAX2SetDocumentLocator($loc);
    }

    method isStandalone(Ctx :$ctx!) returns Bool {
        ? $ctx.xmlSAX2IsStandalone;
    }

    method startDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2StartDocument;
    }

    method endDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2EndDocument;
    }

    method startElement(QName:D $name, CArray :$atts!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElement($name, $atts);
    }

    method endElement(QName:D $name, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElement($name);
    }

    method startElementNs($local-name, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-atts, :$num-defaulted, :$atts, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElementNs($local-name, $prefix, $uri, $num-namespaces, $namespaces, $num-atts, $num-defaulted, $atts);
    }

    method endElementNs($local-name, Str :$prefix, Str :$uri, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElementNs($local-name, $prefix, $uri);
    }

    method characters(Str $chars, Ctx :$ctx!) {
        my Blob $buf = $chars.encode;
        $ctx.xmlSAX2Characters($buf, +$buf);
    }

    method getEntity(Str $name, Ctx :$ctx!) {
        $ctx.xmlSAX2GetEntity($name);
    }
}
