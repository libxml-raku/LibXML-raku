use LibXML::Node;

unit class LibXML::Element
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;
use LibXML::Attr;
use LibXML::Namespace;

multi submethod TWEAK(domNode:D :struct($)!) { }
multi submethod TWEAK(:doc($owner), QName :$name!, xmlNs :$ns) {
    my xmlDoc:D $doc = .unbox with $owner;
    self.struct = xmlNode.new: :$name, :$doc, :$ns;
}

sub iterate(LibXML::Namespace $obj, $start, :$doc = $obj.doc) {
    # follow a chain of .next links.
    my class NodeList does Iterable does Iterator {
        has $.cur;
        method iterator { self }
        method pull-one {
            my $this = $!cur;
            $_ = .next with $!cur;
            with $this -> $node {
                $obj.box: $node, :$doc
            }
            else {
                IterationEnd;
            }
        }
    }.new( :cur($start) );
}

method prefix { .prefix with $.unbox.ns }
method namespaceURI { .href with $.unbox.ns }

method namespaces {
    iterate(LibXML::Namespace, $.unbox.nsDef, :$.doc);
}

method appendText(Str:D $text) {
    $.unbox.appendText($text);
}
