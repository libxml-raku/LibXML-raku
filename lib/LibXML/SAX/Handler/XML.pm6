use LibXML::SAX::Handler::SAX2;

class LibXML::SAX::Handler::XML
    is LibXML::SAX::Handler::SAX2 {

    use XML::Document;
    use XML::Element;
    use XML::Text;
    use NativeCall;
    use LibXML::Document;

    has XML::Element  $!node;
    has XML::Document $.doc;

    use LibXML::SAX::Builder :sax-cb, :atts2Hash;

    method finish(:$doc!) {
        # replace with our own
        $!doc;
    }

    method startElement($name, CArray :$atts) is sax-cb {
        callsame;
        my %attribs := atts2Hash($atts);
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

    method endElement(Str $name) is sax-cb {
        callsame;
        # walk up the tree
        $!node = $!node.parent // Nil;
    }

    method characters(Str $text) is sax-cb {
        callsame;
        .append: XML::Text.new(:$text)
            with $!node;
    }

}
