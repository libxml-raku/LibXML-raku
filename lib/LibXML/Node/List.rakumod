#| LibXML Sibling Node Lists
unit class LibXML::Node::List
    does Iterable;

use LibXML::Raw;
use LibXML::Raw::HashTable;
use LibXML::Item;
use LibXML::Node::Set;
use Method::Also;

has Bool:D $.blank = False;
has $!raw handles <string-value>;
has $.of is required;
has Bool $!reified;
has LibXML::Item @!store;
has $!hstore;
has LibXML::Item $.parent is required;

submethod TWEAK {
    $!raw = do given $!parent.raw {
        when $!of.isa("LibXML::Attr")      { .properties }
        when $!of.isa("LibXML::Namespace") { .nsDef }
        default { .first-child(+$!blank); }
    }
}

method Array handles<AT-POS keys first elems List list values map grep Numeric tail> {
    unless $!reified {
        @!store = self;
        $!reified = True;
    }
    @!store;
}

method AT-KEY(Str() $key) {
    with $!hstore {
        .AT-KEY($key);
    }
    else {
        $!parent.getChildrenByTagName($key);
    }
}

method Hash handles <pairs> {
    $!hstore //= do {
        my xmlHashTable:D $raw = $!parent.raw.Hash(:$!blank);
        (require ::('LibXML::HashMap::NodeSet')).new: :$raw;
    }
}

method push(LibXML::Item:D $node) {
    $.parent.appendChild($node);
    @!store.push($node) if $!reified;
    $!hstore = Nil;
    $node;
} 
method pop {
    do with self.Array.tail -> LibXML::Item $item {
        @!store.pop;
        $!hstore = Nil;
        $item.unbindNode;
    } // $!of;
}
method ASSIGN-POS(UInt() $pos, LibXML::Item:D $item) {
    self.Array unless $!reified;
    if $pos < +@!store {
        $!hstore = Nil; # invalidate Hash cache
        $.parent.replaceChild($item, @!store[$pos]);
        @!store[$pos] = $item;
    }
    elsif $pos == $.elems {
        # allow append of tail element
        $.push($item);
    }
    else {
        fail "array index out of bounds";
    }
}
multi method to-literal( :list($)! where .so ) { self.map(*.string-value) }
multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
method Str is also<gist> { $.Array.map(*.Str).join }

method iterator {
    class iterator does Iterator {
        has Bool:D $.blank is required;
        has $.of is required;
        has $.cur is required;

        method pull-one {
            with $!cur -> $this {
                $!cur = $this.next-node($!blank);
                $!of.box: $this;
            }
            else {
                IterationEnd;
            }
        }
    }
    iterator.new: :$!of, :$!blank, :cur($!raw);
}

method to-node-set {
    my xmlNodeSet:D $raw = $!raw.list-to-nodeset($!blank);
    LibXML::Node::Set.new: :$raw;
}
method ast { self.Array.map(*.ast) }

=begin pod
=head2 Synopsis

  use LibXML::Node::List;
  my LibXML::Node::List $node-list, $att-list;

  $att-list = $elem.attributes;
  $node-list = $elem.childNodes;
  $node-list.push: $elem;

  for $node-list -> LibXML::Node $item { ... }
  for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

  my LibXML::Node::Set %nodes-by-xpath-name = $node-list.Hash;
  # ...

=head2 Description

This class is used for traversing child nodes or attribute lists.

Unlike node-sets, the list is tied to the DOM and can be used to update
nodes.

  # replace 4th child
  $node-list[3] = LibXML::TextNode.new :content("Replacement Text");
  # remove last child
  my $deleted-node = $node-set.pop;
  # append a new child element
  $node-set.push: LibXML::Element.new(:name<NewElem>);

Currently, the only tied methods are `push`, `pop` and `ASSIGN-POS`.


=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod

