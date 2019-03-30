use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr:D :struct($)!) {
}
multi submethod TWEAK(LibXML::Node :$doc!, :$name!, Str :$value!) {
    self.struct = $doc.unbox.NewProp( $name, $value );
}

method unbox handles <atype def defaultValue tree prefix elem name> {
    nextsame;
}

method value is rw { $.nodeValue }

method serializeContent {
    self.unbox.serializeContent;
}

method Str(:$raw) { $raw ?? nextsame() !! $.nodeValue}
