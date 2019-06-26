unit class LibXML::Namespace;
use LibXML::Native;
use LibXML::Types :NCName;
use NativeCall;
use Method::Also;
has xmlNs $!native handles <type prefix href Str>;

method box(xmlNs $ns!) {
    do with $ns {
        self.new: :native($_);
    } // self.WHAT;
}

multi submethod TWEAK(xmlNs:D :$!native!) {
    $!native .= Copy;
    $!native.add-reference;
}

multi submethod TWEAK(Str:D :$URI!, NCName :$prefix, :node($node-obj)) {
    my domNode $node = .native with $node-obj;
    $!native .= new: :$URI, :$prefix, :$node;
    $!native.add-reference;
}

method nodeType     { $!native.type }
method URI is also<declaredURI getData getValue value>
                    { $!native.href }
method localname is also<declaredPrefix getLocalName>
                    { $!native.prefix }
method string-value { $!native.href }
method unique-key   { join('|', $!native.prefix//'', $!native.href//''); }
method nodeName is also<name> {
    $_ ?? 'xmlns:' ~ $_ !! 'xmlns' given $.localname;
}
method getNamespaceURI { 'http://www.w3.org/2000/xmlns/' }
method getPrefix { 'xmlns' }

submethod DESTROY {
    with $!native {
        .Free if .remove-reference;
    }
}

=begin pod
=head1 NAME

LibXML::Namespace - LibXML Namespace Implementation

=head1 SYNOPSIS



  use LibXML::Namespace;
  # Only methods specific to Namespace nodes are listed here,
  # see the LibXML::Node manpage for other methods

  my LibXML::Namespace $ns .= new(:$URI, :$prefix);
  say $ns.nodeName();
  say $ns.name();
  my Str $localname = $ns.getLocalName();
  say $ns.getData();
  say $ns.getValue();
  say $ns.value();
  my Str $known-uri = $ns.getNamespaceURI();
  my Str $known-prefix = $ns.getPrefix();
  $key = $ns.unique-key();

=head1 DESCRIPTION

Namespace nodes are returned by both $element.findnodes('namespace::foo') or
by $node.getNamespaces().

The namespace node API is not part of any current DOM API, and so it is quite
minimal. It should be noted that namespace nodes are I<<<<<< not >>>>>> a sub class of L<<<<<< LibXML::Node >>>>>>, however Namespace nodes act a lot like attribute nodes, and similarly named
methods will return what you would expect if you treated the namespace node as
an attribute.


=head1 METHODS

=begin item
new

  my LibXML::Namespace $ns .= new($nsURI);

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

  say $ns.nodeName();

Returns "xmlns:prefix", where prefix is the prefix for this namespace.
=end item


=begin item
name

  say $ns.name();

Alias for nodeName()
=end item


=begin item
getLocalName

  $localname = $ns.getLocalName();

Returns the local name of this node as if it were an attribute, that is, the
prefix associated with the namespace.
=end item


=begin item
getData

  say $ns.getData();

Returns the URI of the namespace, i.e. the value of this node as if it were an
attribute.
=end item


=begin item
getValue

  say $ns.getValue();

Alias for getData()
=end item


=begin item
value

  print $ns.value();

Alias for getData()
=end item


=begin item
getNamespaceURI

  $known_uri = $ns.getNamespaceURI();

Returns the string "http://www.w3.org/2000/xmlns/"
=end item


=begin item
getPrefix

  $known_prefix = $ns.getPrefix();

Returns the string "xmlns"
=end item


=begin item
unique-key

  $key = $ns.unique-key();

This method returns a key guaranteed to be unique for this namespace, and to
always be the same value for this namespace. Two namespace objects return the
same key if and only if they have the same prefix and the same URI. The
returned key value is useful as a key in hashes.
=end item


=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas


=head1 VERSION

2.0132

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
