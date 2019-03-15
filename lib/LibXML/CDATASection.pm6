use LibXML::Node;

unit class LibXML::CDATASection
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCDataNode:D :struct($)!) { }
multi submethod TWEAK(:doc($owner)!, Str :$content!) {
    my xmlDoc:D $doc = .struct with $owner;
    my xmlCDataNode:D $cdata-struct .= new: :$content, :$doc;
    self.struct = $cdata-struct;
}
