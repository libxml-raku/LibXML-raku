# methods implemented by LibXML::Node and LibXML::Namespace
unit role LibXML::Item;

use LibXML::Native;
use LibXML::Native::DOM::Node;
use LibXML::Enums;
 
method getNamespaceURI {...}
method localname {...}
method name {...}
method nodeName {...}
method nodeType {...}
method prefix {...}
method string-value {...}
method Str {...}
method URI {...}
method type {...}
method value {...}

sub box-class(UInt $_) is export(:box-class) {
    when XML_ATTRIBUTE_NODE     { require LibXML::Attr }
    when XML_ATTRIBUTE_DECL     { require LibXML::AttrDecl }
    when XML_CDATA_SECTION_NODE { require LibXML::CDATA }
    when XML_COMMENT_NODE       { require LibXML::Comment }
    when XML_DTD_NODE           { require LibXML::Dtd }
    when XML_DOCUMENT_FRAG_NODE { require LibXML::DocumentFragment }
    when XML_DOCUMENT_NODE
       | XML_HTML_DOCUMENT_NODE { require LibXML::Document }
    when XML_ELEMENT_NODE       { require LibXML::Element }
    when XML_ELEMENT_DECL       { require LibXML::ElementDecl }
    when XML_ENTITY_DECL        { require LibXML::Entity }
    when XML_ENTITY_REF_NODE    { require LibXML::EntityRef }
    when XML_NAMESPACE_DECL     { require LibXML::Namespace }
    when XML_PI_NODE            { require LibXML::PI }
    when XML_TEXT_NODE          { require LibXML::Text }

    default {
        warn "node content-type not yet handled: $_";
        LibXML::Item;
    }
}

my subset DocNode of LibXML::Item where {!.defined || .type == XML_DOCUMENT_NODE}

method box(LibXML::Native::DOM::Node $struct,
           DocNode :$doc = $.doc, # reusable document object
          ) {
    do with $struct {
        my $class := box-class(.type);
        die "mismatch between DOM node of type {.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
            unless $class ~~ self.WHAT;
        my $native := .delegate;
        $class.new: :$native, :$doc;
    } // self.WHAT; 
}
method unbox { $.native }

method keep(LibXML::Native::DOM::Node $rv,
            DocNode :$doc = $.doc, # reusable document object
            --> LibXML::Item) {
    do with $rv {
        do with self -> $obj {
            die "returned unexpected node: {$.Str}"
                unless $obj.native.isSameNode($_);
            $obj;
        } // self.box: $_, :$doc;
    } // self.WHAT;
}

=begin pod
=head1 NAME

LibXML::Item - LibXML Nodes and Namespaces interface role

=head1 SYNOPSIS



  use LibXML::Item;
  for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
     when LibXML::Namespace { say "namespace: " ~ .Str }
     when LibXML::Attr      { say "attribute: " ~ .Str }
  }

=head1 DESCRIPTON

LibXML::Item is a role performed by LibXML::Namespace and LibXML::Node.

This is a containing role for XPath queries with may return either namespaces or other nodes.

The LibXML::Namespace class is distinct from LibXML::Node classes. It cannot
itself contain namespaces and lacks parent or child nodes.

Both nodes and namespaces support the following common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Please see L<LibXML::Node> and L<LibXML::Namespace>.

=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas,
Shlomi Fish,
Tobias Leich,
Xliff,
David Warring

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
