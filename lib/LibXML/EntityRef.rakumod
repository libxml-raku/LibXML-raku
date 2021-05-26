use LibXML::Node;
use DOM;

unit class LibXML::EntityRef
    is repr('CPointer')
    is LibXML::Node
    does DOM::EntityReference;

use LibXML::Raw;
use NativeCall;
method raw { nativecast(xmlEntityRefNode, self) }

method new(LibXML::Node :doc($owner), Str :$name!) {
    my xmlDoc:D $doc = .raw with $owner;
    my xmlEntityRefNode:D $raw = $doc.new-ent-ref: :$name;
    self.box($raw);
}
method ast { self.ast-key => [] }
