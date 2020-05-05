use LibXML::Item;
#| LibXML Namespace implementation
unit class LibXML::Namespace
    does LibXML::Item;

=begin pod
    =head2 Synopsis

    =begin code :lang<raku>
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
    =end code

    =head2 Description

    Namespace nodes are returned by both $element.findnodes('namespace::foo') or
    by $node.getNamespaces().

    The namespace node API is not part of any current DOM API, and so it is quite
    minimal. It should be noted that namespace nodes are I<<<<<< not >>>>>> a sub class of L<<<<<< LibXML::Node >>>>>>, however Namespace nodes act a lot like attribute nodes (both perform the L<LibXML::Item> role). Similarly named
    methods return what you would expect if you treated the namespace node as an attribute.
=end pod

use LibXML::Native;
use LibXML::Types :NCName;
use NativeCall;
use Method::Also;
use LibXML::Native::Defs :XML_XMLNS_NS;
has xmlNs $!native handles <type href Str>;
method native { $!native }

method box(xmlNs $ns! --> LibXML::Namespace) {
    do with $ns {
        self.new: :native($_);
    } // self.WHAT;
}

method keep($_) {
    given .delegate {
        .prefix ~~ $.declaredPrefix && .href ~~ $.href
            ?? self
            !! self.box($_);
    }
}

# Perl 5 compat
multi method new(Str:D $URI, NCName $prefix?, *%o) {
    self.new(:$URI, :$prefix, |%o);
}

multi method new(|c) is default { nextsame }

=begin pod
    =head2 Methods
=end pod

multi submethod TWEAK(xmlNs:D :$!native!) {
    $!native .= Copy;
}

multi submethod TWEAK(Str:D :$URI!, NCName :$prefix, :node($node-obj)) {
    my xmlElem $node = .native with $node-obj;
    $!native .= new: :$URI, :$prefix, :$node;
}
=begin pod
    =head3 method new
    =begin code :lang<raku>
    method new(Str:D :$URI!, NCName :$prefix, LibXML::Node :$node)
        returns LibXML::Namespace
    =end code
    Creates a new Namespace node. Note that this is not a 'node' as an attribute or
    an element node. Therefore you can't do call all L<<<<<< LibXML::Node >>>>>> Functions. All functions available for this node are listed below.

    Optionally you can pass the prefix to the namespace constructor. If
    `:$prefix` is omitted you will create a so called default namespace. Note, the
    newly created namespace is not bound to any document or node, therefore you
    should not expect it to be available in an existing document.
=end pod

submethod DESTROY {
    .Free with $!native;
}

method nodeType { $!native.type }

#| Returns the URI for this namespace
method declaredURI(--> Str) is also<URI getValue string-value value nodeValue> { $!native.href }

#| Returns the prefix for this namespace
method declaredPrefix(--> NCName) is also<localname>
                    { $!native.prefix }

#| Returns "xmlns:prefix", where prefix is the prefix for this namespace.
method nodeName returns Str is also<name tag> {
    'xmlns' ~ ($_ ?? ':' ~ $_ !! '' given $.localname);
}
=begin pod
    =head3 method name
    =para Alias for nodeName()
=end pod

#| Return a unique key for the namespace
method unique-key returns Str { $!native.UniqueKey }
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

method isSame(LibXML::Item $_) is also<isSameNode> { self.unique-key eq .unique-key }
method xpath-key { 'namespace()' }
method to-ast { self.nodeName => self.nodeValue }
method from-ast($) { fail ".from-ast() - nyi" }

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
