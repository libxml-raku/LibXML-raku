use LibXML::Node;

unit class LibXML::EntityRef
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlEntityRefNode:D :native($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str :$name!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlEntityRefNode:D $entity-ref-struct = $doc.new-ent-ref: :$name;
    self.set-native($entity-ref-struct);
}

method native { callsame() // xmlEntityRefNode }
