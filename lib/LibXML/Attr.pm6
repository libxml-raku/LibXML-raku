use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

use LibXML::Native;
use LibXML::Types :QName;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlAttr:D :struct($)!) {
}
multi submethod TWEAK(LibXML::Node :doc($doc-obj), QName:D :$name!, Str :$value!) {
    my xmlDoc $doc = .unbox with $doc-obj;
    self.struct = xmlAttr.new: :$name, :$value, :$doc;
}

method unbox handles <atype name> {
    nextsame;
}

method value is rw { $.nodeValue }

method serializeContent {
    self.unbox.serializeContent;
}

method Str(:$raw) { $raw ?? nextsame() !! $.nodeValue}
method gist { $.Str(:raw) }
