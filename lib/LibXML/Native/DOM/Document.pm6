unit role LibXML::Native::DOM::Document;

use LibXML::Native::DOM::Node;

use LibXML::Enums;
use LibXML::Types :QName, :NCName;
use NativeCall;

my constant Node = LibXML::Native::DOM::Node;
my subset DocNode of Node where { !.defined || .type == XML_DOCUMENT_NODE } 
my subset DtdNode of Node where { !.defined || .type == XML_DTD_NODE } 

method GetRootElement  { ... }
method SetRootElement  { ... }
method NewProp { ... }
method GetID { ... }
method domCreateAttribute {...}
method domCreateAttributeNS {...}
method domImportNode {...}
method domGetInternalSubset { ... }
method domGetExternalSubset { ... }
method domSetInternalSubset { ... }
method domSetExternalSubset { ... }

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

method createElementNS(Str $URI, QName:D $name is copy) {
    return self.createElement($name) without $URI;
    my Str $prefix;
    given $name.split(':', 2) {
        when 2 {
            $prefix = .[0];
            $name   = .[1];
        }
    }
    my $ns = self.oldNs.new: :$URI, :$prefix;
    self.new-node: :$name, :$ns;
}

method createElement(QName:D $name) {
    self.new-node: :$name;
}

method createAttribute(NCName:D $name, Str $value = '') {
    self.domCreateAttribute($name, $value);
}

my enum <Copy Move>;

multi method importNode(DocNode:D $) { fail "Can't import Document nodes" }
multi method importNode(Node:D $node) is default {
    self.domImportNode($node, Copy, 1);
}

multi method adoptNode(DocNode:D $) { fail "Can't adopt Document nodes" }
multi method adoptNode(Node:D $node) is default {
    self.domImportNode($node, Move, 1);
}

method createAttributeNS(Str $URI, Str:D $name, Str:D $value = '') {
    if $URI {
        self.domCreateAttributeNS($URI, $name, $value);
    }
    else {
        self.domCreateAttribute($name, $value);
    }
}

method getInternalSubset {
    self.domGetInternalSubset;
}

method getExternalSubset {
    self.domGetExternalSubset;
}

method setInternalSubset(DtdNode $dtd) {
    self.domSetInternalSubset($dtd);
}

method setExternalSubset(DtdNode $dtd) {
    self.domSetExternalSubset($dtd);
}

method removeInternalSubset {
    my $rv := self.getInternalSubset;
    .Unlink with $rv;
    $rv;
}

method removeExternalSubset {
    my $rv := self.getExternalSubset;
    .Unlink with $rv;
    $rv;
}

method getElementById(Str:D $id --> Node) {
    my Node $elem = self.GetID($id);
    with $elem {
        $_ .= parent
            if .type == XML_ATTRIBUTE_NODE
    }
    $elem;
}
