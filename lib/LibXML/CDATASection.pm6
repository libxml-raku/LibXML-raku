use LibXML::Node;

unit class LibXML::CDATASection
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, :node($)!) { }
multi submethod TWEAK(:doc($root)!, Str :$content!) {
    my xmlDoc:D $doc = $root.node;
    my xmlCDataNode $node .= new: :$content, :$doc;
    self.set-node: $node;
}
