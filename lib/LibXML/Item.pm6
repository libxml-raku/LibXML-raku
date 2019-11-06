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

proto sub ast-to-xml(|c) is export(:ast-to-xml) {*}

multi sub ast-to-xml(Pair $_) {
    my $name := .key;
    my $value := .value;

    my UInt $node-type := itemNode::NodeType($name);
    if $value ~~ Str {
        when $name.starts-with('#') {
            box-class($node-type).new: :content($value);
        }
        when $name.starts-with('?') {
            $name .= substr(1);
            box-class(XML_PI_NODE).new: :$name, :content($value);
        }
        when $name.starts-with('xmlns:') {
            my $prefix = $name.substr(6);
            box-class(XML_NAMESPACE_DECL).new: :$prefix, :URI($value)
        }
        default {
            box-class(XML_ATTRIBUTE_NODE).new: :$name, :$value;
        }
    }
    else {
         my $node := box-class($node-type).new: :$name;
         $node.add( ast-to-xml($_) ) for $value.List;
         $node;
    }
}

multi sub ast-to-xml(Positional $_) {
    ast-to-xml('#fragment' => $_);
}

multi sub ast-to-xml(Str:D $content) {
    box-class(XML_TEXT_NODE).new: :$content;
}

multi sub ast-to-xml(*%p where .elems == 1) {
    ast-to-xml(%p.pairs[0]);
}

method box(LibXML::Native::DOM::Node $struct,
           :$doc = $.doc, # reusable document object
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
            :$doc = $.doc, # reusable document object
            --> LibXML::Item) {
    do with $rv {
        do with self -> $obj {
            die "returned unexpected node: {$.Str}"
                unless $obj.native.isSameNode($_);
            $obj;
        } // self.box: $_, :$doc;
    } // self.WHAT;
}

method to-ast {...}
method from-ast {...}
method ast(Bool :$blank = False) is rw {
    Proxy.new(
        FETCH => -> $ { self.to-ast(:$blank)  },
        STORE => -> $, Pair $ast { self.from-ast($ast); },
    );
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

LibXML::Item is a role performed by LibXML::Namespace and LibXML::Node based classes.

This is a containing role for XPath queries with may return either namespaces or other nodes.

The LibXML::Namespace class is distinct from LibXML::Node classes. It cannot
itself contain namespaces and lacks parent or child nodes.

Both nodes and namespaces support the following common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Please see L<LibXML::Node> and L<LibXML::Namespace>.

=head1 FUNCTIONS AND METHODS

=begin item1
ast-to-xml()

This function can be useful when it's getting a bit long-winded to create and manipulate data via
the DOM API. For example:

    use LibXML::Elemnt;
    use LibXML::Item :&ast-to-xml;
    my LibXML::Element $elem = ast-to-xml(
        :dromedaries[
                 "\n  ", # white-space
                 '#comment' => ' Element Construction. ',
                 "\n  ", :species[:name<Camel>, :humps["1 or 2"], :disposition["Cranky"]],
                 "\n  ", :species[:name<Llama>, :humps["1 (sort of)"], :disposition["Aloof"]],
                 "\n  ", :species[:name<Alpaca>, :humps["(see Llama)"], :disposition["Friendly"]],
         "\n",
         ]);
     say $elem;

Produces:

    <dromedaries>
      <!-- Element Construction. -->
      <species name="Camel"><humps>1 or 2</humps><disposition>Cranky</disposition></species>
      <species name="Llama"><humps>1 (sort of)</humps><disposition>Aloof</disposition></species>
      <species name="Alpaca"><humps>(see Llama)</humps><disposition>Friendly</disposition></species>
    </dromedaries>

All DOM nodes have an `.ast()` method that can be used to output an intermediate dump of data. In the above example `$elem.ast()` would reproduce thw original data that was used to construct the element.

Possible terms that can be used are:

  =begin table
  *Term* | *Description*
  name => [term, term, ...] | Construct an element and its child items
  name => str-val | Construct an attribute
  xmlns:prefix => str-val | Construct a namespace
  ?name => str-val | Construct a processing instruction
  str-val | Construct text node
  #cdata' => str-val | Construct a CData node
  #comment' => str-val | Construct a comment node
  [elem, elem, ..] | Construct a document fragment
  #xml  => [root-elem] | Construct an XML document
  #html => [root-elem] | Construct an HTML document
  =end table


=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
