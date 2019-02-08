use LibXML::Node;

unit class LibXML::Text
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, :node($)!) { }
multi submethod TWEAK(LibXML::Node :doc($root)!, Str :$content!) {
    my xmlDoc:D $doc = $root.node;
    my xmlTextNode $node .= new: :$content, :$doc;
    self.set-node: $node;
}
