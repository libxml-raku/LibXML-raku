use LibXML::SAX::Handler::SAX2;

class LibXML::SAX::Handler::XML
    is LibXML::SAX::Handler::SAX2 {

    # This class Builds a pure perl 'XML' document,

    use XML::CDATA;
    use XML::Comment;
    use XML::Document;
    use XML::Element;
    use XML::PI;
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
        my $attribs = atts2Hash($atts);
        my XML::Element $elem .= new: :$name, :$attribs;
        # append and step down
        with $!doc {
            $!node.append: $elem;
        }
        else {
            $_ .= new: :root($elem);
        }
        $*ERR.print: '!';
        $!node = $elem;
    }

    method endElement(Str $name) is sax-cb {
        # step up the tree
        $!node = $!node.parent // Nil;
    }

    method cdataBlock(Str $data) is sax-cb {
        .append: XML::CDATA.new(:$data)
            with $!node;
    }

    method characters(Str $text) is sax-cb {
        .append: XML::Text.new(:$text)
            with $!node;
    }

    method comment(Str $text) is sax-cb {
        .append: XML::Comment.new(:$text)
            with $!node;
    }

    method processingInstruction(Str $target, Str $value) is sax-cb {
        my $data = $target ~ ' ' ~ $value;
        .append: XML::PI.new(:$data)
            with $!node;
    }

}
