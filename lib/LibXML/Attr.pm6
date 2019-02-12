use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr :$node!, xmlNs :$ns) {
    $node.ns = $_ with $ns;
}
multi submethod TWEAK(LibXML::Node :doc($root)!, QName :$name!, Str :$value!, xmlNs :$ns) {
    my xmlDoc:D $doc = $root.node;
    my xmlAttr $node = $doc.NewProp( $name, $value );
    $node.ns = $_ with $ns;
    self.node = $node;
}

method node handles <atype def defaultValue tree prefix elem> {
    nextsame;
}

method name is rw { $.nodeName }
method value is rw { $.nodeValue }

method nexth returns LibXML::Attr {
    self.dom-node: $.node.nexth;
}
