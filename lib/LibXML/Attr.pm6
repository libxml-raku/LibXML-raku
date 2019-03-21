use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, domNode:D :struct($)!) {
}
multi submethod TWEAK(LibXML::Node :$doc!, :$name!, Str :$value!) {
    self.struct = $doc.unbox.NewProp( $name, $value );
}

method struct handles <atype def defaultValue tree prefix elem name> {
    nextsame;
}

method value is rw { $.nodeValue }

method nexth returns LibXML::Attr {
    self.box: $.unbox.nexth;
}

method Str(:$raw) { $raw ?? nextsame() !! $.nodeValue}
