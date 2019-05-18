use LibXML::Node;

unit class LibXML::Comment
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCommentNode:D :native($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str :$content!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlCommentNode $comment-struct .= new: :$content, :$doc;
    self.native = $comment-struct;
}
