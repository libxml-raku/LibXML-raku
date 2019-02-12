use LibXML::Node;

unit class LibXML::Comment
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, :node($)!) { }
multi submethod TWEAK(LibXML::Node :doc($root)!, Str :$content!) {
    my xmlDoc:D $doc = $root.node;
    my xmlCommentNode $node .= new: :$content, :$doc;
    self.node = $node;
}
