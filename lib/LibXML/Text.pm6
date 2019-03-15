use LibXML::Node;

unit class LibXML::Text
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlTextNode:D :struct($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str :$content!) {
    my xmlDoc $doc = .struct with $owner;
    my xmlTextNode $text-struct .= new: :$content, :$doc;
    self.struct = $text-struct;
}
