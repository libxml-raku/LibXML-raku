use LibXML::SAX::Builder;
class LibXML::SAX::Builder::XML
    is LibXML::SAX::Builder {
    use XML::Document;
    use XML::Element;
    use XML::Text;

    has XML::Element  $!node;
    has XML::Document $.doc;

    method startElement($name, :atts(%attribs)) {
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
        # walk up the tree
        $!node = $!node.parent // Nil;
    }

    method characters(Str $text) {
        .append: XML::Text.new(:$text)
            with $!node;
    }

}
