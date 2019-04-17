use LibXML::Node;

unit class LibXML::Dtd
    is LibXML::Node;

use LibXML::Native;
use LibXML::ErrorHandler;

method unbox handles <publicId systemId> {
    nextsame;
}

multi submethod TWEAK(xmlDtd:D :struct($)!) { }
multi submethod TWEAK(
    Str:D :$type!,
    LibXML::Node :doc($owner), Str:D :$name!,
    Str :$external-id, Str :$system-id, ) {
    my xmlDoc $doc = .unbox with $owner;
    my xmlDtd:D $dtd-struct .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.struct = $dtd-struct;
}

multi method new($name, $external-id, *%o) {
    self.new(:$name, :$external-id, :type<external>, |%o);
}

multi method new(|c) is default { nextsame }

multi method parse(Str :$string!, xmlEncodingStr:D :$enc = 'UTF-8') {
    my xmlDtd:D $struct = LibXML::ErrorHandler.new.try: {xmlDtd.parse: :$string, :$enc};
    self.new: :$struct;
}
multi method parse(Str :$external-id, Str :$system-id) {
    my xmlDtd:D $struct = LibXML::ErrorHandler.new.try: {xmlDtd.parse: :$external-id, :$system-id;};
    self.new: :$struct;
}
multi method parse(Str $external-id, Str $system-id) is default {
    self.parse: :$external-id, :$system-id;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) {
    my xmlDtd:D $struct = self.unbox.copy;
    self.clone: :$struct;
}
