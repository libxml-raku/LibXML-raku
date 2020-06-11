use LibXML::Node;

unit class LibXML::Entity
    is LibXML::Node;

use LibXML::Native;

multi method new(Str:D :$name!, Str:D :$content!, Str :$external-id, Str :$internal-id, LibXML::Item :$doc) {
    my xmlEntity:D $native .= create: :$name, :$content, :$external-id, :$internal-id;
    self.box($native, :$doc);
}

method native { callsame() // xmlEntity }
