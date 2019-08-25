use v6;
unit class LibXML::XPath::Object;

use LibXML::Item;
use LibXML::Native;
use LibXML::Node :iterate-set;
use LibXML::Node::Set;

has xmlXPathObject:D $.native is required handles<type>;
method native { with self { $!native } else { xmlXPathObject } }

my subset XPathRange is export(:XPathRange) where Bool|Numeric|Str|LibXML::Node::Set;
my subset XPathDomain is export(:XPathDomain) where XPathRange|LibXML::Item;

method coerce-to-native(XPathDomain $content is copy) {
    if $content ~~ LibXML::Item|LibXML::Node::Set {
        $content .= native;
        # node-sets can't be multiply referenced
        $content .= copy if $content ~~ xmlNodeSet;
    }

    xmlXPathObject.coerce($content);
}


method coerce($content) {
    my xmlXPathObject:D $native = self.coerce-to-native($content);
    self.new: :$native;
}

method value(Bool :$literal,  --> XPathRange) {
    given $!native.value {
        when xmlNodeSet {
            given iterate-set(LibXML::Item, .copy) {
                $literal ?? .to-literal !! $_;
            }
        }
        default { $_ }
    }
}

submethod TWEAK { $!native.Reference }
submethod DESTROY { $!native.Unreference }
