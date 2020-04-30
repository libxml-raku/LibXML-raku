use LibXML::Item;
unit class LibXML::Namespace
    does LibXML::Item;

use LibXML::Native;
use LibXML::Types :NCName;
use NativeCall;
use Method::Also;
use LibXML::Native::Defs :XML_XMLNS_NS;
has xmlNs $!native handles <type href Str>;
method native { $!native }

method box(xmlNs $ns!) {
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

multi submethod TWEAK(xmlNs:D :$!native!) {
    $!native .= Copy;
}

multi submethod TWEAK(Str:D :$URI!, NCName :$prefix, :node($node-obj)) {
    my xmlElem $node = .native with $node-obj;
    $!native .= new: :$URI, :$prefix, :$node;
}

submethod DESTROY {
    .Free with $!native;
}

method nodeType { $!native.type }
method nodeName is also<name tag> {
    'xmlns' ~ ($_ ?? ':' ~ $_ !! '' given $.localname);
}
method URI is also<declaredURI getValue string-value value nodeValue>
                    { $!native.href }
method localname(--> NCName) is also<declaredPrefix>
                    { $!native.prefix }
method unique-key   { $!native.UniqueKey }
method isSame(LibXML::Item $_) is also<isSameNode> { self.unique-key eq .unique-key }
method xpath-key { 'namespace()' }
method getNamespaceURI { XML_XMLNS_NS }
method prefix { 'xmlns' }
method to-ast { self.nodeName => self.nodeValue }
method from-ast($) { fail ".from-ast() - nyi" }

=begin pod
=head1 NAME

LibXML::Namespace - LibXML Namespace Implementation

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Namespace nodes are returned by both $element.findnodes('namespace::foo') or
by $node.getNamespaces().

The namespace node API is not part of any current DOM API, and so it is quite
minimal. It should be noted that namespace nodes are I<<<<<< not >>>>>> a sub class of L<<<<<< LibXML::Node >>>>>>, however Namespace nodes act a lot like attribute nodes (both perform the L<LibXML::Item> role). Similarly named
methods return what you would expect if you treated the namespace node as an attribute.


=head1 METHODS

=begin item
new
  =begin code :lang<raku>
  my LibXML::Namespace $ns .= new: :$URI, :$prefix;
  =end code
Creates a new Namespace node. Note that this is not a 'node' as an attribute or
an element node. Therefore you can't do call all L<<<<<< LibXML::Node >>>>>> Functions. All functions available for this node are listed below.

Optionally you can pass the prefix to the namespace constructor. If this second
parameter is omitted you will create a so called default namespace. Note, the
newly created namespace is not bound to any document or node, therefore you
should not expect it to be available in an existing document.
=end item

=begin item
declaredURI

Returns the URI for this namespace.
=end item

=begin item
declaredPrefix

Returns the prefix for this namespace.
=end item


=begin item
nodeName
  =begin code :lang<raku>
  say $ns.nodeName();
  =end code
Returns "xmlns:prefix", where prefix is the prefix for this namespace.
=end item


=begin item
name
  =begin code :lang<raku>
  say $ns.name();
  =end code
Alias for nodeName()
=end item


=begin item
getLocalName
  =begin code :lang<raku>
  my Str $localname = $ns.getLocalName();
  =end code
Returns the local name of this node as if it were an attribute, that is, the
prefix associated with the namespace.
=end item


=begin item
getData
  =begin code :lang<raku>
  say $ns.getData();
  =end code
Returns the URI of the namespace, i.e. the value of this node as if it were an
attribute.
=end item


=begin item
getValue
  =begin code :lang<raku>
  say $ns.getValue();
  =end code
Alias for getData()
=end item


=begin item
value
  =begin code :lang<raku>
  say $ns.value();
  =end code
Alias for getData()
=end item


=begin item
getNamespaceURI
  =begin code :lang<raku>
  my Str $known-uri = $ns.getNamespaceURI();
  =end code
Returns the string "http://www.w3.org/2000/xmlns/"
=end item


=begin item
getPrefix
  =begin code :lang<raku>
  my Str $known-prefix = $ns.getPrefix();
  =end code
Returns the string "xmlns"
=end item


=begin item
unique-key
  =begin code :lang<raku>
  my Str $key = $ns.unique-key();
  =end code
This method returns a key guaranteed to be unique for this namespace, and to
always be the same value for this namespace. Two namespace objects return the
same key if and only if they have the same prefix and the same URI. The
returned key value is useful as a key in hashes.
=end item


=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
