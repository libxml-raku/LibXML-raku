#| Build pure Raku XML documents using LibXML's SAX parser
class LibXML::SAX::Handler::XML {

    use LibXML::SAX::Handler::SAX2;
    also is LibXML::SAX::Handler::SAX2;

    # This class Builds a Raku 'XML' document,

    use XML::CDATA;
    use XML::Comment;
    use XML::Document;
    use XML::Element;
    use XML::PI;
    use XML::Text;
    use LibXML::SAX::Builder :sax-cb;

    has XML::Document $.doc is built;  # The document that we're really building
    has XML::Node  $!node;             # Current node

    method publish($) {
        # ignore SAX created document; replace with our own
        $!doc;
    }

    method startDocument is sax-cb {
        $!doc .= new;
        $!node = $!doc;
    }

    method startElement($name, :%attribs) is sax-cb {
        my XML::Element $elem .= new: :$name, :%attribs;
        $!node.append: $elem;
        $!node = $elem;
    }

    method endElement(Str $name) is sax-cb {
        # step up the tree
        $!node = $!node.parent // Nil;
    }

    method cdataBlock(Str $data) is sax-cb {
        $!node.append: XML::CDATA.new(:$data);
    }

    method characters(Str $text) is sax-cb {
        $!node.append: XML::Text.new(:$text);
    }

    method comment(Str $text) is sax-cb {
        $!node.append: XML::Comment.new(:$text);
    }

    method processingInstruction(Str $target, Str $value) is sax-cb {
        my $data = $target ~ ' ' ~ $value;
        $!node.append: XML::PI.new(:$data);
    }

}
=begin pod

=head2 Synopsis

    use LibXML;
    use LibXML::SAX::Handler::XML;
    use XML::Document;

    my LibXML::SAX::Handler::XML $sax-handler .= new;
    my XML::Document $doc = LibXML.parse: :file</tmp/ee.xml>, :$sax-handler;

=head2 Description

L<LibXML::SAX::Handler::XML> is a SAX handler that produce a pure Raku L<XML::Document>
object using the LIBXML SAX interface to parse the document.

This class is an example of implementing a custom parser using the
LibXML SAX interface, L<LibXML::SAX::Builder> and  L<LibXML::SAX::Handler::SAX2>.


=end pod
