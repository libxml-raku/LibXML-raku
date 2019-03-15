use LibXML::Node;

unit class LibXML::Comment
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCommentNode:D :struct($)!) { }
multi submethod TWEAK(LibXML::Node :doc($root)!, Str :$content!) {
    my xmlDoc:D $doc = $root.struct;
    my xmlCommentNode $comment-struct .= new: :$content, :$doc;
    self.struct = $comment-struct;
}
