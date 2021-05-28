use LibXML::Node;
use W3C::DOM;

unit class LibXML::Entity
    is repr('CPointer')
    is LibXML::Node
    does W3C::DOM::Entity;

use LibXML::Raw;
use NativeCall;

multi method new(Str:D :$name!, Str:D :$content!, Str :$external-id, Str :$internal-id, LibXML::Item :$doc) {
    my xmlEntity:D $native .= create: :$name, :$content, :$external-id, :$internal-id;
    self.box($native, :$doc);
}

method publicId { $.raw.ExternalID }
method systemId { $.raw.SystemID }
method notationName { $.nodeName }

method raw { nativecast(xmlEntity, self) }
