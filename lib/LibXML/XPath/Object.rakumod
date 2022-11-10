use v6;
unit class LibXML::XPath::Object;

use LibXML::Item;
use LibXML::Raw;
use LibXML::Types :XPathRange;
use LibXML::_Configurable;
use LibXML::_Collection;
use NativeCall;

also does LibXML::Types::XPathish;
also does LibXML::_Configurable;
also does LibXML::_Collection;

has xmlXPathObject:D $.raw is required;

submethod TWEAK { $!raw.Reference }

submethod DESTROY { $!raw.Unreference }

method coerce-to-raw(XPathRange $content is copy) {
    xmlXPathObject($content ~~ LibXML::Types::XPathish ?? $content.raw !! $content)
}

multi method COERCE(XPathRange:D $content) {
    self.create: raw => self.coerce-to-raw($content)
}

method coerce($v) is DEPRECATED<COERCE> { self.COERCE: $v }

method value(xmlXPathObject :$raw = $.raw, Bool :$literal, *%c  --> XPathRange) {
    given $raw.value {
        when xmlNodeSet {
            given self.iterate-set(LibXML::Item, .copy) {
                $literal ?? .to-literal !! $_;
            }
        }
        when anyNode {
            $literal ?? .Str !! LibXML::Item.box: $_, |%c;
        }
        default { $_ }
    }
}

