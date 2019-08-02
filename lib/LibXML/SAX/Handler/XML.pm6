use LibXML::SAX::Handler::SAX2;

class LibXML::SAX::Handler::XML
    is LibXML::SAX::Handler::SAX2 {

    # This class Builds a pure perl 'XML' document,

    use XML::Document;
    use XML::Element;
    use XML::Text;
    use NativeCall;
    use LibXML::Document;

    has XML::Document $.doc; # The document that we're really building
    has XML::Element  $!node; # Current node

    use LibXML::SAX::Builder :sax-cb, :atts2Hash;

    method finish(LibXML::Document:D :doc($)!) {
        # ignore SAX created document; replace with our own
        $!doc;
    }

    method startElement($name, CArray :$atts) is sax-cb {
        callsame;
        my $attribs = atts2Hash($atts);
        my XML::Element $elem .= new: :$name, :$attribs;
        # append and step down
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
        # step up the tree
        $!node = $!node.parent // Nil;
    }

    method characters(Str $text) is sax-cb {
        callsame;
        .append: XML::Text.new(:$text)
            with $!node;
    }

}
