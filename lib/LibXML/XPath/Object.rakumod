use v6;
unit class LibXML::XPath::Object
    is repr('CPointer');

use LibXML::Item;
use LibXML::Raw;
use LibXML::Node :iterate-set;
use LibXML::Node::Set;
use NativeCall;

method new(xmlXPathObject:D :$raw!) {
    $raw.Reference;
    nativecast(LibXML::XPath::Object, $raw);
}

method raw { nativecast(xmlXPathObject, self) }

submethod DESTROY { self.raw.Unreference }

my subset XPathRange is export(:XPathRange) where Bool|Numeric|Str|LibXML::Node::Set;
my subset XPathDomain is export(:XPathDomain) where XPathRange|LibXML::Item;

method !coerce-to-raw(XPathDomain $content is copy) {
    if $content ~~ LibXML::Item|LibXML::Node::Set {
        $content .= raw;
        # node-sets can't be multiply referenced
        $content .= copy if $content ~~ xmlNodeSet;
    }

    xmlXPathObject.coerce($content);
}

method coerce($content) {
    my xmlXPathObject:D $raw = self!coerce-to-raw($content);
    self.new: :$raw;
}

method value(Bool :$literal,  --> XPathRange) {
    given $.raw.value {
        when xmlNodeSet {
            given iterate-set(LibXML::Item, .copy) {
                $literal ?? .to-literal !! $_;
            }
        }
        default { $_ }
    }
}

