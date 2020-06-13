use LibXML::Node;

unit class LibXML::Entity
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Raw;
use NativeCall;

multi method new(Str:D :$name!, Str:D :$content!, Str :$external-id, Str :$internal-id, LibXML::Item :$doc) {
    my xmlEntity:D $native .= create: :$name, :$content, :$external-id, :$internal-id;
    self.box($native, :$doc);
}

method raw { nativecast(xmlEntity, self) }
