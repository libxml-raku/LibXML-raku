use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr :$node!, xmlNs :$ns) {
    $node.ns = $_ with $ns;
}
multi submethod TWEAK(LibXML::Node :$doc!, QName :$name!, Str :$value!, xmlNs :$ns) {
    my xmlAttr $node = $doc.node.NewProp( $name, $value );
    $node.ns = $_ with $ns;
    self.node = $node;
}

method node handles <atype def defaultValue tree prefix elem name> {
    nextsame;
}

method value is rw { $.nodeValue }

method nexth returns LibXML::Attr {
    self.dom-node: $.node.nexth;
}
