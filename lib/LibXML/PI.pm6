use LibXML::Node;

unit class LibXML::PI
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, :node($)!) { }
multi submethod TWEAK(:doc($root)!, Str :$name!, Str :$content!) {
    my xmlDoc:D $doc = $root.node;
    my xmlPINode:D $node .= new: :$name, :$content, :$doc;
    self.node = $node;
}
