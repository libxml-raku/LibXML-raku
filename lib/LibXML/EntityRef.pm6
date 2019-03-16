use LibXML::Node;

unit class LibXML::EntityRef
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlEntityRefNode:D :struct($)!) { }
multi submethod TWEAK(:doc($owner)!, Str :$name!) {
    my xmlDoc:D $doc = .struct with $owner;
    my xmlEntityRefNode:D $entity-ref-struct = $doc.new-ent-ref: :$name;
    self.struct = $entity-ref-struct;
}
