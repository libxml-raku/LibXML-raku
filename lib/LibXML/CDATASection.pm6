use LibXML::Node;

unit class LibXML::CDATASection
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCDataNode:D :struct($)!) { }
multi submethod TWEAK(:doc($root)!, Str :$content!) {
    my xmlDoc:D $doc = $root.struct;
    my xmlCDataNode:D $cdata-struct .= new: :$content, :$doc;
    self.struct = $cdata-struct;
}
