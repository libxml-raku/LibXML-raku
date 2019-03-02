use LibXML::Node;

unit class LibXML::Element
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;
use LibXML::Attr;
use LibXML::Namespace;

multi submethod TWEAK(xmlNode:D :node($)!) { }
multi submethod TWEAK(:doc($root), QName :$name!, xmlNs :$ns) {
    my xmlDoc:D $doc = .node with $root;
    self.node = xmlNode.new: :$name, :$doc, :$ns;
}

method namespaces {
    LibXML::Node::iterate(LibXML::Namespace, $.node.nsDef, :$.doc);
}

