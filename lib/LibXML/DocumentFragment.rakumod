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
use LibXML::Parser::Context;

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

class ParserContext is LibXML::Parser::Context {
    has LibXML::DocumentFragment $.doc-frag is required;
    has Int $.stat is rw;
    has Str $.string;
    has Pointer $.user-data;
    has Pointer[xmlNode] $.nodes is rw .= new();
}

multi method parse(
    Str() :$string!,
    Bool :balanced($)! where .so,
    Pointer :$user-data,
    |c) {

    my $doc-frag = self;
    $_ .= new(|c) without $doc-frag;
    my $flags = 

    my ParserContext $ctx .= new: :$string, :$doc-frag, :$user-data, |c;

    $ctx.try: {
        # simple closures tend to leak on native callbacks. use dynamic variables
        my $ctx := $*XML-CONTEXT;
        my xmlSAXHandler $sax = .native with $ctx.sax-handler;
        my $doc = $ctx.doc-frag.native.doc;
        my Pointer $user-data = $ctx.user-data;
        temp LibXML::Native.KeepBlanksDefault = $ctx.keep-blanks;

        $ctx.stat = ($doc // xmlDoc).xmlParseBalancedChunkMemoryRecover(
            ($sax // xmlSAXHandler), ($ctx.user-data // Pointer), 0, $ctx.string, $ctx.nodes, +$ctx.recover
        );
        die "balanced parse failed with status {$ctx.stat}"
            if $ctx.stat && !$ctx.recover;
    };

    $doc-frag.native.AddChildList($_) with $ctx.nodes.deref;
    $doc-frag;
}

method Str(|c) is also<serialize serialise> {
    $.childNodes.map(*.Str(|c)).join;
}

=begin pod
=head1 NAME

LibXML::DocumentFragment - LibXML's DOM L2 Document Fragment Implementation

=head1 SYNOPSIS

  =begin code :lang<raku>
  use LibXML::Document;
  use LibXML::DocumentFragment;
  my LibXML::Document $doc .= new;

  my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
  say $frag.Str; # '<foo/><bar/>';
  $frag.parse: :balanced, :string('<baz/>');
  say $frag.Str; # '<foo/><bar/><baz>';

  $frag = $doc.createDocumentFragment;
  $frag.appendChild: $doc.createElement('foo');
  $frag.appendChild: $doc.createElement('bar');
  $frag.parse: :balanced, :string('<baz/>');
  say $frag.Str # '<foo/><bar/><baz/>'

  $frag = $some-elem.removeChildNodes();

  use LibXML::Item :&ast-to-xml;
  $frag = ast-to-xml([
               '#comment' => 'demo',         # comment
               "\n  ",                       # whitespace
               :baz[],                       # element
               '#cdata' => 'a&b',            # CData section
                "Some text.\n",               # text content
      ]);
  say $frag; # <!--demo--><baz/><![CDATA[a&b]]>Some text.
  =end code

=head1 DESCRIPTION

This class is a helper class as described in the DOM Level 2 Specification. It
is implemented as a node without name. All adding, inserting or replacing
functions are aware of document fragments.

=head1 METHODS

The class inherits from L<<<<<< LibXML::Node >>>>>>. The documentation for Inherited methods is not listed here.

=begin item
new
  =begin code :lang<raku>
  my LibXML::Document $doc; # owner document for the fragment;
  my LibXML::DocumentFragment $frag .= new: :$doc, *%parser-options;
  =end code
Creates a new empty document fragment to which nodes can be added; typically by
calling the `parse()` method or using inherited `LibXML::Node` DOM methods, for example, `.addChild()`.
=end item

=begin item
parse
  =begin code :lang<raku>
  my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>'), :recover, :suppress-warnings, :suppress-errors, *%parser-options;
  =end code
Performs a parse of the given XML fragment and appends the resulting nodes to the fragment. The `parse()` method may be called multiple times on a document fragment object to append nodes.

=end item

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
