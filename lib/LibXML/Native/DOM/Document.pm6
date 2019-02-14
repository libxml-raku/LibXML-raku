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

method createElementNs(Str:D $href, QName:D $name) {
    my ($prefix, $localname) = $name.split(":");
    $localname //= $prefix;
    my $ns = self.oldNs.new: :$href, :$prefix;
    self.NewNode($ns, $localname, '');
}

method createElement(NCName:D $name) {
    self.NewNode(Nil, $name, '');
}

method createAttribute(NCName:D $name, Str $value = '') {
    self.domCreateAttribute($name, $value);
}

method createAttributeNS(Str:D $href, Str:D $name is copy, Str:D $value = '') {
    fail "need to create documentElement first"
        without $.documentElement;
    self.domCreateAttributeNS($href, $name, $value);
}
