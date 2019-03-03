use LibXML::Node;

unit class LibXML::DocumentFragment
    is LibXML::Node;

use LibXML::Document;
use LibXML::Native;
use LibXML::Element;
use NativeCall;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlDocFrag:D :node($)!) {}
multi submethod TWEAK(LibXML::Node :doc($doc-obj)!) {
    my xmlDoc:D $doc = .node with $doc-obj;
    my xmlDocFrag $node .= new: :$doc;
    self.node = $node;
}

method parse-balanced(Str() :$chunk!,
                      xmlSAXHandler :$sax,
                      Pointer :$user-data,
                      Bool() :$repair = False) {
    my Pointer[xmlNode] $nodes .= new;
    # may return a linked list of nodes
    my $stat = xmlDoc.xmlParseBalancedChunkMemoryRecover(
        $sax, $user-data, 0, $chunk, $nodes, +$repair
    );
    die "balanced parse failed with status $stat"
        if $stat && !$repair;

    my xmlNode $new-node = $nodes.deref;

    # replace old nodes
    my $old-node = $.node.children;
    while $old-node.defined {
        $old-node.Unlink;
        $old-node.Free unless .is-referenced;
        $old-node .= next;
    }
    .add-reference with $new-node;
    $.node.set-nodes($new-node);

    $stat;
}

method Str(Bool :$format = False) {
    $.childNodes.map(*.Str(:$format)).join;
}

