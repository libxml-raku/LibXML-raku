use LibXML::Node;

unit class LibXML::DocumentFragment
    is LibXML::Node;

use LibXML::Document;
use LibXML::Native;
use LibXML::Element;
use NativeCall;

submethod TWEAK() {
    self.set-node: xmlDocFrag.new;
}

method root { self }

method parse-balanced(Str() :$chunk!, xmlSAXHandler :$sax, Pointer :$user-data,  Bool() :$repair) {
    my Pointer[xmlNode] $nodes .= new;
    my $stat = xmlDoc.xmlParseBalancedChunkMemory($sax, $user-data, 0, $chunk, $nodes);
    if $stat && !$repair {
        .deref.FreeList with $nodes;
    }
    else {
        with $nodes {
            .FreeList with $.node.children;
            $.node.set-nodes(.deref);
        }
    }
    $stat;
}

method Str(Bool :$format = False) {
    $.childNodes.map(*.Str(:$format)).join;
}

submethod DESTROY {
    with self.node {
        .FreeList with self.node.children;
	self.set-node: _xmlNode;
    }
}


