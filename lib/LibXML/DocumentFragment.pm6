use LibXML::Node;

unit class LibXML::DocumentFragment
    is LibXML::Node;

use LibXML::Document;
use LibXML::Native;
use LibXML::Element;
use NativeCall;

multi submethod TWEAK(LibXML::Node :doc($)!, :node($)!) {}
multi submethod TWEAK(:doc($root)!) {
    my xmlDoc:D $doc = .node with $root;
    my xmlDocFrag $node .= new: :$doc;
    self.node = $node;
}

method parse-balanced(Str() :$chunk!,
                      xmlSAXHandler :$sax,
                      Pointer :$user-data,
                      Bool() :$repair) {
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

