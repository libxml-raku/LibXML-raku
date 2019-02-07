use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(:root($)!, :node($)!) { }
multi submethod TWEAK(:$root!, Str :$name!, Str :$value!) {
    my xmlDoc:D $doc = $root.node;
    my xmlAttr $node .= new: :$name, :$value, :$doc;
    self.set-node: $node;
}

method node handles <atype def defaultValue tree prefix elem> {
    nextsame;
}

method name is rw { $.nodeName }
method value is rw { $.nodeValue }

method nexth returns LibXML::Attr {
    self.dom-node: $.node.nexth;
}
