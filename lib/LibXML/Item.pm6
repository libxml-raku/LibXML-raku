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

my constant @ClassMap = do {
    my Str @map;
    for (
        'LibXML::Attr'             => XML_ATTRIBUTE_NODE,
        'LibXML::Dtd::Attr'        => XML_ATTRIBUTE_DECL,
        'LibXML::CDATA'            => XML_CDATA_SECTION_NODE,
        'LibXML::Comment'          => XML_COMMENT_NODE,
        'LibXML::Dtd'              => XML_DTD_NODE,
        'LibXML::DocumentFragment' => XML_DOCUMENT_FRAG_NODE,
        'LibXML::Document'         => XML_DOCUMENT_NODE,
        'LibXML::Document'         => XML_HTML_DOCUMENT_NODE,
        'LibXML::Document'         => XML_DOCB_DOCUMENT_NODE,
        'LibXML::Element'          => XML_ELEMENT_NODE,
        'LibXML::Dtd::Element'     => XML_ELEMENT_DECL,
        'LibXML::Entity'           => XML_ENTITY_DECL,
        'LibXML::EntityRef'        => XML_ENTITY_REF_NODE,
        'LibXML::Namespace'        => XML_NAMESPACE_DECL,
        'LibXML::PI'               => XML_PI_NODE,
        'LibXML::Text'             => XML_TEXT_NODE,
    ) {
        @map[.value] = .key
    }
    @map;
}

sub item-class($class-name) is export(:item-class) {
    my $class = ::($class-name);
    $class ~~ LibXML::Item
        ?? $class
        !! (require ::($class-name));
}

sub box-class(UInt $_) is export(:box-class) {
    item-class(@ClassMap[$_] // 'LibXML::Item');
}

proto sub ast-to-xml(|c) is export(:ast-to-xml) {*}

multi sub ast-to-xml(Pair $_) {
    my $name = .key;
    my $value := .value;

    my UInt $node-type := itemNode::NodeType($name);
    if $value ~~ Str:D {
        when $name.starts-with('#') {
            box-class($node-type).new: :content($value);
        }
        when $name.starts-with('?') {
            $name .= substr(1);
            item-class('LibXML::PI').new: :$name, :content($value);
        }
        when $name.starts-with('xmlns:') {
            my $prefix = $name.substr(6);
            item-class('LibXML::Namespace').new: :$prefix, :URI($value)
        }
        default {
            $name .= substr(1) if $name.starts-with('@');
            item-class('LibXML::Attr').new: :$name, :$value;
        }
    }
    else {
        if $name.starts-with('&') {
            $name .= substr(1);
            $name .= chop() if $name.ends-with(';');
        }
        my $node := box-class($node-type).new: :$name;
        for $value.List {
            $node.add( ast-to-xml($_) ) if .defined;
        }
        $node;
    }
}

multi sub ast-to-xml(Positional $_) {
    ast-to-xml('#fragment' => $_);
}

multi sub ast-to-xml(Str:D $content) {
    item-class('LibXML::Text').new: :$content;
}

multi sub ast-to-xml(LibXML::Item:D $_) { $_ }

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

=head1 DESCRIPTON

LibXML::Item is a role performed by LibXML::Namespace and LibXML::Node based classes.

These are distinct classes in libxml2, but do share common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Also note that the LibXML::Node `findnodes` method can sometimes return either LibXML::Node or LibXML::Namespace items, e.g.:

  use LibXML::Item;
  for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
     when LibXML::Namespace { say "namespace: " ~ .Str }
     when LibXML::Attr      { say "attribute: " ~ .Str }
  }

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
  'xmlns:prefix' => str-val | Construct a namespace
  'text content' | Construct text node
  '?name' => str-val | Construct a processing instruction
  '#cdata' => str-val | Construct a CData node
  '#comment' => str-val | Construct a comment node
  [elem, elem, ..] | Construct a document fragment
  '#xml'  => [root-elem] | Construct an XML document
  '#html' => [root-elem] | Construct an HTML document
  '&name' => [] | Construct an entity reference
  =end table


=end item1

=begin item1
box

By convention native classes in the LibXML module are not directly exposed, but have a containing class
that manages the native object and provides an API interface to it. The `box` method is used to stantiate
the containing object, of an appropriate class. The class will in-turn reference-count or copy the object
to ensure that the underlying native object is not destroyed while the containing object is still alive.

For example to create an xmlElem native object then a LibXML::Element containing class.

   use LibXML::Native;
   use LibXML::Node;
   use LibXML::Element;

   my xmlElem $native .= new: :name<Foo>;
   say $native.type; # 1 (element)
   my LibXML::Element $elem = LibXML::Node.box($native);
   $!native := Nil;
   say $elem.Str; # <Foo/>

A containing object of the correct type (LibXML::Element) has been created for the native object.

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
