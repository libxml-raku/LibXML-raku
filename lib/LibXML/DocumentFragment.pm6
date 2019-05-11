use LibXML::Node;

unit class LibXML::DocumentFragment
    is LibXML::Node;

use LibXML::Document;
use LibXML::Native;
use LibXML::Element;
use NativeCall;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlDocFrag:D :struct($)!) {}
multi submethod TWEAK(LibXML::Node :doc($doc-obj)) {
    my xmlDoc:D $doc = .unbox with $doc-obj;
    my xmlDocFrag $doc-frag-struct .= new: :$doc;
    self.struct = $doc-frag-struct;
}

#| don't try to keep document fragment return values. They're unpacked
#! and discarded by the DOM
method keep(|c) { LibXML::Node.box(|c) }

multi method parse(
    Str() :$string!,
    Bool :balanced($)! where .so,
    xmlSAXHandler :$sax,
    Pointer :$user-data,
    Bool() :$repair = False) {
    my Pointer[xmlNode] $nodes .= new;
    # may return a linked list of nodes
    my $stat = (self.unbox.doc // xmlDoc).xmlParseBalancedChunkMemoryRecover(
        $sax, $user-data, 0, $string, $nodes, +$repair
    );
    die "balanced parse failed with status $stat"
        if $stat && !$repair;

    $.unbox.AddChildList($_) with $nodes.deref;

    $stat;
}

method Str(|c) {
    $.childNodes.map(*.Str(|c)).join;
}

