use LibXML::Node;

unit class LibXML::PI
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlPINode:D :struct($)!) { }
multi submethod TWEAK(:doc($owner)!, Str :$name!, Str :$content!) {
    my xmlDoc:D $doc = .struct with $owner;
    my xmlPINode:D $pi-struct .= new: :$name, :$content, :$doc;
    self.struct = $pi-struct;
}
