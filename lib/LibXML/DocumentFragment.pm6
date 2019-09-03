use LibXML::Node;
use LibXML::_DOMNode;

unit class LibXML::DocumentFragment
    is LibXML::Node
    does LibXML::_DOMNode;

use LibXML::Config;
use LibXML::Document;
use LibXML::Element;
use LibXML::Native;
use LibXML::Node;
use NativeCall;
use Method::Also;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlDocFrag:D :native($)!) {}
multi submethod TWEAK(LibXML::Node :doc($doc-obj)) {
    my xmlDoc:D $doc = .native with $doc-obj;
    my xmlDocFrag $doc-frag-struct .= new: :$doc;
    self.set-native: $doc-frag-struct;
}

method native { callsame() // xmlDocFrag }

# The native DOM returns the document fragment content as
# a nodelist; rather than the fragment itself
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

=begin pod
=head1 NAME

LibXML::DocumentFragment - LibXML's DOM L2 Document Fragment Implementation

=head1 SYNOPSIS


  use LibXML::Document;
  use LibXML::DocumentFragment;
  my LibXML::Document $doc .= new;
  my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
  say $frag.Str # '<foo/><bar/>'
  my LibXML::DocumentFragment $frag2 = $doc.createDocumentFragment;
  $frag2.appendChild: $doc.createElement('foo');
  $frag2.appendChild: $doc.createElement('bar');
  say $frag2.Str # '<foo/><bar/>'

=head1 DESCRIPTION

This class is a helper class as described in the DOM Level 2 Specification. It
is implemented as a node without name. All adding, inserting or replacing
functions are aware of document fragments.

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
