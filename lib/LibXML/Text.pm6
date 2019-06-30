use LibXML::Node;
use LibXML::_TextNode;

unit class LibXML::Text
    is LibXML::Node
    does LibXML::_TextNode;

use LibXML::Native;
use Method::Also;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlTextNode:D :native($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str() :$content!) {
    my xmlDoc $doc = .native with $owner;
    my xmlTextNode $text-struct .= new: :$content, :$doc;
    self.native = $text-struct;
}

method content is rw handles<substr substr-rw> { $.native.content };

