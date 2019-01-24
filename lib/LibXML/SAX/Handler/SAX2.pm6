# a base class that provides a full set of SAX2 callbacks
# commonly used as a base class
use LibXML::SAX::Handler;
class LibXML::SAX::Handler::SAX2
    is LibXML::SAX::Handler {
    use LibXML::Native;
    use NativeCall;

    constant LIB = LibXML::Native::LIB;
    constant Ctx = parserCtxt;

    method startElement(Str $name, CArray :raw-atts($atts)!, Ctx :$ctx!) {
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
