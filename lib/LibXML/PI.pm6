use LibXML::Node;

unit class LibXML::PI
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlPINode:D :native($)!) { }
multi submethod TWEAK(:doc($owner)!, Str :$name!, Str :$content!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlPINode:D $pi-struct .= new: :$name, :$content, :$doc;
    self.native = $pi-struct;
}
