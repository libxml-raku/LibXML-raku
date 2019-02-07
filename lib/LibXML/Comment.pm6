use LibXML::Node;

unit class LibXML::Comment
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(:root($)!, :node($)!) { }
multi submethod TWEAK(:$root!, Str :$content!) {
    my xmlDoc:D $doc = $root.node;
    my xmlCommentNode $node .= new: :$content, :$doc;
    self.set-node: $node;
}
