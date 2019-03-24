unit role LibXML::Native::DOM::Document;

use LibXML::Native::DOM::Node;

use LibXML::Enums;
use LibXML::Types :QName, :NCName;
use NativeCall;

my constant Node = LibXML::Native::DOM::Node;
my subset DocishNode of Node where { !.defined || .type == XML_DTD_NODE|XML_DOCUMENT_NODE } 

method GetRootElement  { ... }
method SetRootElement  { ... }
method NewProp { ... }
method domCreateAttribute {...}
method domCreateAttributeNS {...}
method domImportNode {...}

method documentElement is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetRootElement },
        STORE => sub ($, Node $e) {
            with self.GetRootElement {
                return if .isSameNode($e);
                .Release;
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

my enum <Copy Move>;

multi method importNode(DocishNode:D $) { fail "Can't import Document/DTD nodes" }
multi method importNode(Node:D $node) is default {
    self.domImportNode($node, Copy, 1);
}

multi method adoptNode(DocishNode:D $) { fail "Can't adopt Document/DTD nodes" }
multi method adoptNode(Node:D $node) is default {
    self.domImportNode($node, Move, 1);
}

method createAttributeNS(Str $href, Str:D $name, Str:D $value = '') {
    if $href {
        self.domCreateAttributeNS($href, $name, $value);
    }
    else {
        self.domCreateAttribute($name, $value);
    }
}
