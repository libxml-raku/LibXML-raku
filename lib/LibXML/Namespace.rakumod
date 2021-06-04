use LibXML::Item;
use LibXML::_DomNode;
#| LibXML Namespace implementation
unit class LibXML::Namespace
    is repr('CPointer')
    is LibXML::Item
    does LibXML::_DomNode;

=begin pod
    =head2 Synopsis

        use LibXML::Namespace;
        my LibXML::Namespace $ns .= new(:$URI, :$prefix);
        say $ns.nodeName();
        say $ns.name();
        my Str $localname = $ns.localname();
        say $ns.getValue();
        say $ns.value();
        my Str $known-uri = $ns.getNamespaceURI();
        my Str $known-prefix = $ns.prefix();
        $key = $ns.unique-key();

    =head2 Description

    Namespace nodes are returned by both $element.findnodes('namespace::foo') or
    by $node.getNamespaces().

    The namespace node API is not part of any current DOM API, and so it is quite
    minimal. It should be noted that namespace nodes are I<not> a sub class of L<LibXML::Node>, however Namespace nodes act a lot like attribute nodes (both are based on L<LibXML::Item>). Similarly named
    methods return what you would expect if you treated the namespace node as an attribute.
=end pod

use LibXML::Raw;
use LibXML::Types :NCName;
use NativeCall;
use Method::Also;
use LibXML::Enums;
use LibXML::Raw::Defs :XML_XMLNS_NS;
method raw handles<type href Str> { nativecast(xmlNs, self) }
method native is DEPRECATED<raw> { self.raw }

multi method box(LibXML::Namespace $_) { $_ }
multi method box(xmlNs:D $raw --> LibXML::Namespace) {
    nativecast(LibXML::Namespace, $raw.Copy);
}
multi method box(itemNode:D $raw --> LibXML::Namespace) {
    fail "not a namespace node"
        unless .type == XML_NAMESPACE_DECL;
    nativecast(LibXML::Namespace, $raw.delegate.Copy);
}

method keep($_) {
    given .delegate -> xmlNs:D $ns {
        $ns.prefix ~~ $.declaredPrefix && $ns.href ~~ $.href
            ?? self
            !! self.box($_);
    }
}

multi method new(xmlNs:D :native($_)!) is DEPRECATED<box> { self.box: $_ }

# Perl 5 compat
multi method new(Str:D $URI, NCName $prefix?, |c) {
    self.new: :$URI, :$prefix, |c;
}

multi method new(Str:D :$URI!, NCName :$prefix, LibXML::Item :node($node-obj)) {
    my xmlElem $node = .raw with $node-obj;
    my xmlNs:D $raw .= new: :$URI, :$prefix, :$node;
    self.box: $raw;
}

=head2 Methods

=begin pod
    =head3 method new

        method new(Str:D :$URI!, NCName :$prefix, LibXML::Node :$node)
            returns LibXML::Namespace

    Creates a new Namespace node. Note that this is not a 'node' as an attribute or
    an element node. Therefore you can't do call all L<LibXML::Node> Functions. All functions available for this node are listed below.

    Optionally you can pass the prefix to the namespace constructor. If
    `:$prefix` is omitted you will create a so called default namespace. Note, the
    newly created namespace is not bound to any document or node, therefore you
    should not expect it to be available in an existing document.
=end pod

submethod DESTROY {
    self.raw.Free;
}

method nodeType { $.raw.type }

#| Returns the URI for this namespace
method declaredURI(--> Str) is also<URI getValue string-value value nodeValue> { $.raw.href }

#| Returns the prefix for this namespace
method declaredPrefix(--> NCName) is also<localname>
                    { $.raw.prefix }

#| Returns "xmlns:prefix", where prefix is the prefix for this namespace.
method nodeName returns Str is also<name tag> {
    'xmlns' ~ ($_ ?? ':' ~ $_ !! '' given $.localname);
}
=begin pod
    =head3 method name
    =para Alias for nodeName()
=end pod

#| Return a unique key for the namespace
method unique-key returns Str { $.raw.UniqueKey }
=begin pod
    =para
    This method returns a key guaranteed to be unique for this namespace, and to
    always be the same value for this namespace. Two namespace objects return the
    same key if and only if they have the same prefix and the same URI. The
    returned key value is useful as a key in hashes.
=end pod

#| Returns the string "http://www.w3.org/2000/xmlns/"
method getNamespaceURI returns Str { XML_XMLNS_NS }

#| Returns the string "xmlns"
method prefix returns Str { 'xmlns' }

method isSame(LibXML::Item $_) is also<isSameNode> {
    .isa($?CLASS) && self.unique-key eq .unique-key
}
method xpath-key { 'namespace()' }
method ast { self.nodeName => self.nodeValue }

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
