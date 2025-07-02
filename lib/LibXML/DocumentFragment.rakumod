#| LibXML's DOM L2 Document Fragment Implementation
unit class LibXML::DocumentFragment;

use LibXML::Node;
use LibXML::Enums;
use LibXML::Raw;
use LibXML::_ParentNode;
use LibXML::_Rawish;
use W3C::DOM;

also is LibXML::Node;
also does LibXML::_ParentNode;
also does LibXML::_Rawish[xmlDocFrag, <encoding setCompression getCompression standalone wellFormed>];
also does W3C::DOM::DocumentFragment;

=begin pod
    =head2 Synopsis

        use LibXML::Document;
        use LibXML::DocumentFragment;

        my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
        say $frag.Str; # '<foo/><bar/>';
        $frag.parse: :balanced, :string('<baz/>');
        say $frag.Str; # '<foo/><bar/><baz/>';

        my LibXML::Document $doc .= parse: :string("<doc/>");
        $doc.root.addChild($frag);
        say $doc.root.Str; # <doc><foo/><bar/><baz/></doc>

        $frag = $doc.createDocumentFragment;
        $frag.addChild: $doc.createElement('foo');
        $frag.addChild: $doc.createElement('bar');
        $frag.parse: :balanced, :string('<baz/>');
        say $frag.Str; # '<foo/><bar/><baz/>'

        $frag = $some-elem.removeChildNodes();

        use LibXML::Item :&ast-to-xml;
        $frag = ast-to-xml([
                     '#comment' => 'demo',         # comment
                     "\n  ",                       # white-space
                     :baz[],                       # element
                     '#cdata' => 'a&b',            # CData section
                      "Some text.\n",               # text content
            ]);
        say $frag; # <!--demo--><baz/><![CDATA[a&b]]>Some text.

    =head2 Description

    A Document Fragment differs from both L<LibXML::Document> and L<LibXML::Element> in that it
    may contain multiple root nodes. It is commonly used as an intermediate object when assembling
    or editing documents. All adding, inserting or replacing
    functions are aware of document fragments.

    It is a helper class as described in the DOM Level 2 Specification.

=end pod

use LibXML::Element;
use LibXML::Node;
use NativeCall;
use Method::Also;

class ParserContext {
    use LibXML::Parser::Context;
    also is LibXML::Parser::Context;

    has LibXML::DocumentFragment $.doc-frag is required;
    has Int $.stat is rw;
    has Str $.string;
    has Pointer $.user-data;
    has xmlNode $.nodes is rw;
    my Lock:D $lock .= new;

    submethod DESTROY {
        $lock.protect: {
            .FreeList() with $!nodes;
        }
    }
    method publish {
        callsame();
        my xmlNode $rv;
        $lock.protect: {
            if $!nodes {
                $rv = $!nodes;
                $!nodes = Nil;
            }
        }
        $rv;
    }
}

=begin pod
    =head2 Methods

    The class inherits from L<LibXML::Node>. The documentation for Inherited methods is not listed here.
=end pod

# The native DOM returns the document fragment content as
# a node-list; rather than the fragment itself
method keep(|c) { LibXML::Node.box(:$.config, |c) }

method new(LibXML::Node :doc($_), xmlDocFrag :$native, *%c) {
    my xmlDoc:D $doc = .raw with $_;
    self.box: $native // xmlDocFrag.new(:$doc), |%c;
}
=begin pod
    =head3 method new

        method new(LibXML::Document :$doc) returns LibXML::DocumentFragment

    Creates a new empty document fragment to which nodes can be added; typically by
    calling the `parse()` method or using inherited `LibXML::Node` DOM methods, for example, `.addChild()`.
=end pod

#| parses a balanced XML chunk
proto method parse(
    Str:D() :$string!,
    Bool :balanced($)! where .so,
    Pointer :$user-data,
    --> LibXML::DocumentFragment) {
    {*}
}

multi method parse(
  ::?CLASS:U:
  Str:D() :$string,
  Bool :balanced($)! where .so,
  Pointer :$user-data,
 |c) is hidden-from-backtrace {
    self.new(|c).parse: :$string, :balanced, :$user-data, |c;
}

multi method parse(
    ::?CLASS:D $doc-frag:
    Str:D() :$string!,
    Bool :balanced($)! where .so,
    Pointer :$user-data,
    |c
    --> LibXML::DocumentFragment) is hidden-from-backtrace {

    my ParserContext $ctx = $doc-frag.create: ParserContext, :$string, :$doc-frag, :$user-data, |c;

    $ctx.do: {
        if $.config.version >= v2.14.0 {
            my xmlDoc:D $doc = self.raw.doc // xmlDoc.new;
            my $raw = ($doc.isHTMLish
                ?? htmlParserCtxt.new
                !! xmlParserCtxt.new);
            my xmlParserInput $input .= new: :$string;
            $raw.myDoc = $doc;
            $ctx.set-raw: $raw;
            $ctx.nodes = $raw.ParseContent($input, $doc, 0);
        }
        else {
            my xmlSAXHandler $sax = .raw with $ctx.sax-handler;
            my $doc = $ctx.doc-frag.raw.doc;
            my Pointer $user-data = $ctx.user-data;
            temp LibXML::Raw.KeepBlanksDefault = $ctx.keep-blanks;
            my Pointer[xmlNode] $nodes-p .= new;
            $ctx.stat = ($doc // xmlDoc).xmlParseBalancedChunkMemoryRecover(
                            ($sax // xmlSAXHandler), ($ctx.user-data // Pointer), 0, $ctx.string, $nodes-p, +$ctx.recover
                        );
            $ctx.nodes = $nodes-p ?? $nodes-p.deref !! Nil;
        }

        LEAVE .close() with $ctx;
    }
    # just in case, we didn't catch the error
    die "balanced parse failed with status {$ctx.stat}"
        if $ctx.stat && !$ctx.recover;

    $doc-frag.raw.AddChildList($_) with $ctx.publish;
    $doc-frag;
}
=begin pod
    =para
    Returns a new document fragment object, if called on a class; appends nodes if called on an object instance.
    Example:

        my LibXML::DocumentFragment $frag .= parse(
            :balanced, :string('<foo/><bar/>'),
            :recover, :suppress-warnings, :suppress-errors
        );

    =para Performs a parse of the given XML fragment and appends the resulting nodes to the fragment. The `parse()` method may be called multiple times on a document fragment object to append nodes.

    It accepts a full range of parser options as described in L<LibXML::Parser>
=end pod

method Str(|c) is also<serialize serialise> {
    $.childNodes.map(*.Str(|c)).join;
}

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
