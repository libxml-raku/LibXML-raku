# a base class that provides a full set of SAX2 callbacks
use LibXML::SAX::Handler;

class LibXML::SAX::Handler::SAX2
    is LibXML::SAX::Handler {
    use LibXML::Native;
    use NativeCall;
    use LibXML::SAX::Handler::SAX2::Locator;
    has LibXML::SAX::Handler::SAX2::Locator $.locator handles<line-number column-number> .= new;

    use LibXML::Document;
    use LibXML::DocumentFragment;
    use LibXML::Types :QName, :NCName;

    multi method publish(LibXML::Document :$doc!) {
        $doc;
    }
    multi method publish(LibXML::DocumentFragment :$doc!) {
        $doc;
    }

    constant Ctx = xmlParserCtxt;

    method isStandalone(Ctx :$ctx!) returns Bool {
        ? $ctx.xmlSAX2IsStandalone;
    }

    method startDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2StartDocument;
    }

    method endDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2EndDocument;
    }

    method startElement(QName:D $name, CArray :$atts-raw!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElement($name, $atts-raw);
    }

    method endElement(QName:D $name, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElement($name);
    }

    method startElementNs($local-name, Str :$prefix!, Str :$uri!, UInt :$num-namespaces!, CArray :$namespaces!, UInt :$num-atts!, UInt :$num-defaulted!, CArray :$atts-raw!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElementNs($local-name, $prefix, $uri, $num-namespaces, $namespaces, $num-atts, $num-defaulted, $atts-raw);
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
