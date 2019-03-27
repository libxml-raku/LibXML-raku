use LibXML::Node;

unit class LibXML::Dtd
    is LibXML::Node;

use LibXML::Native;

method struct handles<publicId systemId> {
    nextsame;
}

multi submethod TWEAK(domNode:D :struct($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str :$name!, Str :$external-id, Str :$system-id, :$internal, :$external) {
    my xmlDoc $doc = .unbox with $owner;
    my xmlDtd:D $dtd-struct .= new: :$doc, :$name, :$external-id, :$system-id, :$internal, :$external;
    self.struct = $dtd-struct;
}

multi method parse(Str :$string!, xmlCharEncoding:D :$enc = 'UTF-8') {
    my xmlDtd:D $struct .= parse: :$string, :$enc;
    self.new: :$struct;
}
multi method parse(Str :$external-id, Str :$system-id) is default {
    my xmlDtd:D $struct .= parse: :$external-id, :$system-id;
    self.new: :$struct;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) {
    my xmlDtd:D $struct = self.unbox.copy;
    self.clone: :$struct;
}
