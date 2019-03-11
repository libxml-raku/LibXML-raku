use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr:D :node($)!) {
}
multi submethod TWEAK(LibXML::Node :$doc!, :$name!, Str :$value!) {
    self.node = $doc.node.NewProp( $name, $value );
}

method node handles <atype def defaultValue tree prefix elem name> {
    nextsame;
}

method value is rw { $.nodeValue }

method nexth returns LibXML::Attr {
    self.dom-node: $.node.nexth;
}

method Str { $.nodeValue }
