use LibXML::Node;

unit class LibXML::Entity
    is LibXML::Node;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlEntity:D :native($)!) { }
multi submethod TWEAK(Str:D :$name!, Str:D :$content!, Str :$external-id, Str :$internal-id) {
    my xmlEntity:D $entity-struct .= create: :$name, :$content, :$external-id, :$internal-id;
    self.set-native($entity-struct);
}

method native { callsame() // xmlEntity }
