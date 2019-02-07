use LibXML::Node;

unit class LibXML::Element
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(:root($)!, :node($)!) { }
multi submethod TWEAK(:$root!, QName :$name!, xmlNs :$ns) {
    my xmlDoc:D $doc = $root.node;
    my xmlNode $node .= new: :$name, :$doc, :$ns;
    self.set-node: $node;
}

use LibXML::Namespace;
method attributes {
    LibXML::Node::iterate(self, $.node.properties);
}

method namespaces {
    LibXML::Node::iterate(LibXML::Namespace, $.node.nsDef, :$.root);
}

