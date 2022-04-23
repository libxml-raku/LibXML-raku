use v6;
unit class LibXML::XPath::Object
    is repr('CPointer');

use LibXML::Item;
use LibXML::Raw;
use LibXML::Utils :iterate-set;
use LibXML::Types :XPathRange;
use NativeCall;

also does LibXML::Types::XPathish;

method new(xmlXPathObject:D :$raw!) {
    $raw.Reference;
    nativecast(self.WHAT, $raw);
}

method raw { nativecast(xmlXPathObject, self) }

submethod DESTROY { self.raw.Unreference }

method coerce-to-raw(XPathRange $content is copy) {
    $content .= raw()
        if $content ~~ LibXML::Types::XPathish;
    xmlXPathObject.coerce($content);
}

method coerce($content) {
    my xmlXPathObject:D $raw = self.coerce-to-raw($content);
    self.new: :$raw;
}

method value(xmlXPathObject :$raw = $.raw, Bool :$literal,  --> XPathRange) {
    given $raw.value {
        when xmlNodeSet {
            given iterate-set(LibXML::Item, .copy) {
                $literal ?? .to-literal !! $_;
            }
        }
        when anyNode {
            $literal ?? .Str !! LibXML::Item.box: $_;
        }
        default { $_ }
    }
}

