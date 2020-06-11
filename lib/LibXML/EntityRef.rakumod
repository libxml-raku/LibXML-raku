use LibXML::Node;

unit class LibXML::EntityRef
    is LibXML::Node;

use LibXML::Native;

proto method native(--> xmlEntityRefNode) {*}
multi method native(LibXML::EntityRef:D:) { self.raw }
multi method native(LibXML::EntityRef:U:) { xmlEntityRefNode }

multi method new(LibXML::Node :doc($owner), Str :$name!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlEntityRefNode:D $native = $doc.new-ent-ref: :$name;
    self.box($native, :doc($owner));
}
method ast { self.ast-key => [] }
