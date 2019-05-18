use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr:D :native($)!) {
}
multi submethod TWEAK(LibXML::Node :doc($doc-obj), QName:D :$name!, Str :$value!) {
    my xmlDoc $doc = .native with $doc-obj;
    self.native = xmlAttr.new: :$name, :$value, :$doc;
}

method native handles <atype name serializeContent> {
    nextsame;
}

method value is rw { $.nodeValue }

method Str { $.nodeValue}
method gist(|c) { $.native.Str(|c) }
