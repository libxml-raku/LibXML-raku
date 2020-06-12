use LibXML::Node;

unit class LibXML::EntityRef
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Native;

use LibXML::Native;
use NativeCall;
method raw { nativecast(xmlEntityRefNode, self) }

method new(LibXML::Node :doc($owner), Str :$name!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlEntityRefNode:D $raw = $doc.new-ent-ref: :$name;
    self.box($raw);
}
method ast { self.ast-key => [] }
