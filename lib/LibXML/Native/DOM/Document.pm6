unit role LibXML::Native::DOM::Document;

use LibXML::Native::DOM::Node;

my constant Node = LibXML::Native::DOM::Node;

use LibXML::Enums;
use LibXML::Types :QName, :NCName;
use NativeCall;

method GetRootElement  { ... }
method SetRootElement  { ... }
method NewProp { ... }
method domCreateAttribute {...}
method domCreateAttributeNS {...}

method documentElement is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetRootElement },
        STORE => sub ($, Node $e) {
            with self.GetRootElement {
                return if .isSameNode($e);
                self.removeChild($_);
                .Free unless .is-referenced;
            }
            self.SetRootElement($e);
        });
}

method createElementNS(Str $href, QName:D $name is copy) {
    return self.createElement($name) without $href;
    my Str $prefix;
    given $name.split(':', 2) {
        when 2 {
            $prefix = .[0];
            $name   = .[1];
        }
    }
    my $ns = self.oldNs.new: :$href, :$prefix;
    self.new-node: :$name, :$ns;
}

method createElement(QName:D $name) {
    self.new-node: :$name;
}

method createAttribute(NCName:D $name, Str $value = '') {
    self.domCreateAttribute($name, $value);
}

method createAttributeNS(Str $href, Str:D $name, Str:D $value = '') {
    fail "need to create documentElement first"
        without $.documentElement;
    self.domCreateAttributeNS($href, $name, $value);
}
