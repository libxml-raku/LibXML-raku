use LibXML::SAX::Handler::SAX2;

class LibXML::SAX::Handler::XML
    is LibXML::SAX::Handler::SAX2 {

    use XML::Document;
    use XML::Element;
    use XML::Text;

    has XML::Element  $!node;
    has XML::Document $.doc;

    method startElement($name, :atts(%attribs)) {
        callsame;
        my XML::Element $elem .= new: :$name, :%attribs;
        # append and walk down
        with $!doc {
            $!node.append: $elem;
        }
        else {
            $_ .= new: :root($elem);
        }
        $!node = $elem;
    }

    method endElement(Str $name) {
        callsame;
        # walk up the tree
        $!node = $!node.parent // Nil;
    }

    method characters(Str $text) {
        callsame;
        .append: XML::Text.new(:$text)
            with $!node;
    }

}
