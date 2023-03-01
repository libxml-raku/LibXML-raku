#| base class for namespaces and nodes
unit class LibXML::Item;

=begin pod
    =head2 Name

    LibXML::Item is a base class for L<LibXML::Namespace> and L<LibXML::Node> based classes.

    These are distinct classes in libxml2, but do share common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

    Also note that the L<LibXML::Node> `findnodes` method can sometimes return either L<LibXML::Node> or L<LibXML::Namespace> items, e.g.:

      use LibXML::Item;
      for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
         when LibXML::Namespace { say "namespace: " ~ .Str }
         when LibXML::Attr      { say "attribute: " ~ .Str }
      }

    Please see L<LibXML::Node> and L<LibXML::Namespace>.

    =head2 Functions and Methods
=end pod

use LibXML::Raw;
use LibXML::Raw::DOM::Node;
use LibXML::Enums;
use LibXML::Types :resolve-package;
use LibXML::Config;
use LibXML::_Configurable;

also does LibXML::Types::Itemish;
also does LibXML::Types::XPathish;
also does LibXML::_Configurable;

method raw { itemNode }

sub box-class($_) is export(:box-class) {
    ::?CLASS.box-class($_)
}

proto sub ast-to-xml(|) is export(:ast-to-xml) {*}
multi sub ast-to-xml($_) { ::?CLASS.ast-to-xml($_) }
multi sub ast-to-xml(*%p where .elems == 1) { ::?CLASS.ast-to-xml(%p.pairs.head) }

proto method box-class($) {*}
multi method box-class(::?CLASS $_) { $_ }
multi method box-class(Str:D $class-name) { resolve-package($class-name) }
multi method box-class(::?CLASS:U: Int:D $id) { LibXML::Config.class-from($id) }
multi method box-class(::?CLASS:D: Int:D $id) { $!config.class-from($id) }

proto method box(|) {*}
multi method box(::?CLASS:D: Any:D $_, *%c) { (%c<config> //= $.config).class-from(.type).box(.delegate, |%c) }
multi method box(::?CLASS:U: Any:D $_, *%c) { (%c<config> //  $.config).class-from(.type).box(.delegate, |%c) }
multi method box(Any:U \raw-type, :$config) { ($config    //  $.config).box(raw-type, { self.WHAT }) }

#| Node constructor from data
proto method ast-to-xml(::?CLASS:D: | --> LibXML::Item) {*}
=begin pod
This function can be useful as a succinct of building nodes from data. For example:

    use LibXML::Element;
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
    =begin code :lang<xml>
    <dromedaries>
      <!-- Element Construction. -->
      <species name="Camel"><humps>1 or 2</humps><disposition>Cranky</disposition></species>
      <species name="Llama"><humps>1 (sort of)</humps><disposition>Aloof</disposition></species>
      <species name="Alpaca"><humps>(see Llama)</humps><disposition>Friendly</disposition></species>
    </dromedaries>
    =end code
=end pod

multi method ast-to-xml(Pair $_) {
    my $name = .key;
    my $value := .value;

    my UInt $node-type := itemNode::NodeType($name);
    my $config = $.config // LibXML::Config.new;

    when $value ~~ Str:D {
        when $name.starts-with('#') {
            self.box-class($node-type).new: :content($value), :$config;
        }
        when $name.starts-with('?') {
            $name .= substr(1);
            $config.class-from(XML_PI_NODE).new: :$name, :content($value), :$config;
        }
        when $name eq 'xmlns' {
            $config.class-from(XML_NAMESPACE_DECL).new: :URI($value), :$config;
        }
        when $name.starts-with('xmlns:') {
            my $prefix = $name.substr(6);
            $config.class-from(XML_NAMESPACE_DECL).new: :$prefix, :URI($value), :$config;
        }
        default {
            $name .= substr(1) if $name.starts-with('@');
            $config.class-from(XML_ATTRIBUTE_NODE).new: :$name, :$value, :$config;
        }
    }
    when $name.starts-with('&') {
        $name .= substr(1);
        $name .= chop() if $name.ends-with(';');
        $config.class-from(XML_ENTITY_REF_NODE).new: :$name, :$config;
    }
    default {
        my $node := self.box-class($node-type).new: :$name, :$config;

        for $value.List {
            $node.add( self.ast-to-xml($_) ) if .defined;
        }
        $node;
    }
}

multi method ast-to-xml(Positional $_) {
    self.ast-to-xml('#fragment' => $_);
}

multi method ast-to-xml(Str:D $content) {
    self.box-class(XML_TEXT_NODE).new: :$content, :$.config
}

multi method ast-to-xml(LibXML::Item:D $_) { $_ }

multi method ast-to-xml(*%p where .elems == 1) {
    self.ast-to-xml(%p.pairs.head);
}

=begin pod

    =para
    All DOM nodes have an `.ast()` method that can be used to output an intermediate dump of data. In the above example `$elem.ast()` would reproduce thw original data that was used to construct the element.

    Possible terms that can be used are:

    =begin table
    Term | Description
    =====+============  
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
    LibXML::Item | Reuse an existing node or namespace
    =end table

=end pod


=begin pod
    =para
    By convention native classes in the LibXML module are not directly exposed, but have a containing class
    that holds the object in a `$.raw` attribute and provides an API interface for it. The `box` method is used to stantiate
    a containing object, of an appropriate class. The containing object will in-turn reference-count or copy the object
    to ensure that the underlying raw object is not destroyed while it is still alive.

    For example to box xmlElem raw object:

     use LibXML::Raw;
     use LibXML::Node;
     use LibXML::Element;

     my xmlElem $raw .= new: :name<Foo>;
     say $raw.type; # 1 (element)
     my LibXML::Element $elem .= box($raw);
     $raw := Nil;
     say $elem.Str; # <Foo/>

    A containing object of the correct type (LibXML::Element) has been created for the native object.

=end pod

# replace yada with a call to the underlying raw method
multi trait_mod:<is>( Method $m where {.yada && .count <= 1 && .returns ~~ ::?CLASS},
                      :$dom-boxed!
                     ) is export(:dom-boxed)
{
    my $name := $dom-boxed ~~ Str:D ?? $dom-boxed !! $m.name;
    my $class := $m.returns;
    my &wrapper = method (::?CLASS:D:) is hidden-from-backtrace {
#        note "BOXING on ", self.WHICH, " into {$class.^name} for method '$name' --> ", $.raw."$name"().WHICH;
        self.box: $class, $.raw."$name"()
    };
    &wrapper.set_name($name);
    $m.wrap: &wrapper;
}

#| Utility method that verifies that `$raw` is the same native struct as the current object.
proto method keep(LibXML::Raw::DOM::Node $ --> LibXML::Item) {*}

multi method keep(::?CLASS:D $obj: LibXML::Raw::DOM::Node:D $raw) {
    die "returned unexpected node: {$raw.Str}"
        unless $obj.raw.isSameNode($raw);
    $obj;
}
multi method keep(::?CLASS:U: LibXML::Raw::DOM::Node:D $raw) {
    self.box: $raw;
}
multi method keep(Any:U $raw) {
    self.WHAT
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
