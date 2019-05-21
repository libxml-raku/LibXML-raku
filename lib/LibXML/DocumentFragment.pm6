use LibXML::Node;

unit class LibXML::DocumentFragment
    is LibXML::Node;

use LibXML::Document;
use LibXML::Native;
use LibXML::Element;
use LibXML::Config;
use NativeCall;
use Method::Also;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlDocFrag:D :native($)!) {}
multi submethod TWEAK(LibXML::Node :doc($doc-obj)) {
    my xmlDoc:D $doc = .native with $doc-obj;
    my xmlDocFrag $doc-frag-struct .= new: :$doc;
    self.native = $doc-frag-struct;
}

#| don't try to keep document fragment return values. They're unpacked
#! and discarded by the DOM
method keep(|c) { LibXML::Node.box(|c) }
my constant config = LibXML::Config;

multi method parse(
    Str() :$string!,
    Bool :balanced($)! where .so,
    xmlSAXHandler :$sax,
    Pointer :$user-data,
    Bool() :$repair = False,
    Bool() :$keep-blanks = config.keep-blanks-default ) {
    my Pointer[xmlNode] $nodes .= new;
    my $stat;
    # may return a linked list of nodes
    do {
        temp LibXML::Native.KeepBlanksDefault = $keep-blanks;
        $stat := (self.native.doc // xmlDoc).xmlParseBalancedChunkMemoryRecover(
            $sax, $user-data, 0, $string, $nodes, +$repair
        );
        die "balanced parse failed with status $stat"
            if $stat && !$repair;
    }

    $.native.AddChildList($_) with $nodes.deref;

    $stat;
}

method Str(|c) is also<serialize serialise> {
    $.childNodes.map(*.Str(|c)).join;
}

