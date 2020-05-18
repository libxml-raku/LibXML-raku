#| LibXML Sibling Node Lists
unit class LibXML::Node::List
    does Iterable
    does Iterator;

use LibXML::Native;
use LibXML::Item;
use Method::Also;

has Bool:D $.blank = False;
has $.doc is required;
has $!native handles <string-value>;
has LibXML::Item $!first;
has $!cur;
has $.of is required;
has int $.idx = 0;
has LibXML::Item @!store;
has Hash $!hstore;
has Bool $!lazy = True;
has LibXML::Item $.parent is required;

submethod TWEAK {
    $!native = do given $!parent.native {
        when $!of.isa("LibXML::Attr")      { .properties }
        when $!of.isa("LibXML::Namespace") { .nsDef }
        default { .first-child(+$!blank); }
    }
    $!first = $!of.box: $_ with $!native;
    $!cur = $!native;
    $!idx = 0;
}

method Array handles<elems List list values map grep Numeric tail> {
    if $!lazy-- {
        $!idx = 0;
        $!cur = $!native;
        @!store = self;
    }
    @!store;
}
method first { $!first }

# allow lazy incremental iteration
method AT-POS(UInt() $pos) {
    when $pos == $!idx {
        # current element
        $!of.box: $!cur, :$!doc;
    }
    when $pos == $!idx+1 {
        # next element
        $!idx++;
        $_ = .next-node($!blank) with $!cur;
        $!of.box: $!cur, :$!doc;
    }
    default {
        # switch to random access
        self.Array.AT-POS($pos);
    }
}
method Hash handles <AT-KEY> {
    $!hstore //= do {
        my $set-class := (require ::('LibXML::Node::Set'));
        my %h = ();
        for self.Array {
            (%h{.xpath-key} //= $set-class.new: :deref).add: $_;
        }
        %h;
    }
}

method push(LibXML::Item:D $node) {
    $.parent.appendChild($node);
    @!store.push($node) unless $!lazy;
    .{$node.xpath-key}.push: $node with $!hstore;
    $node;
} 
method pop {
    do with self.Array.tail -> LibXML::Item $item {
        @!store.pop;
        .{$item.xpath-key}.pop with $!hstore;
        $item.unbindNode;
    } // $!of;
}
method ASSIGN-POS(UInt() $pos, LibXML::Item:D $item) {
    if $pos < $.elems {
        $!hstore = Nil; # invalidate Hash cache
        $.parent.replaceChild($item, $.Array[$pos]);
        $!cur = $item.native if $pos == $!idx;
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
    $!cur = $!native;
    self;
}
method pull-one {
    with $!cur -> $this {
        $!idx++;
        $!cur = $this.next-node($!blank);
        $!of.box: $this, :$!doc
    }
    else {
        IterationEnd;
    }
}
method to-node-set {
    my xmlNodeSet:D $native = $!native.list-to-nodeset($!blank);
    (require ::('LibXML::Node::Set')).new: :$native;
}
method ast { self.Array.map(*.ast) }

=begin pod
=head2 Synopsis
  =begin code :lang<raku>
  use LibXML::Node::List;
  my LibXML::Node::List $node-list, $att-list;

  $att-list = $elem.attributes;
  $node-list = $elem.childNodes;
  $node-list.push: $elem;

  for $node-list -> LibXML::Node $item { ... }
  for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

  my LibXML::Node::Set %nodes-by-xpath-name = $node-list.Hash;
  # ...
  =end code

=head2 Description

This class is used for traversing child nodes or attribute lists.

Unlike node-sets, the list is tied to the DOM and can be used to update
nodes.
  =begin code :lang<raku>
  # replace 4th child
  $node-list[3] = LibXML::TextNode.new :content("Replacement Text");
  # remove last child
  my $deleted-node = $node-set.pop;
  # append a new child element
  $node-set.push: LibXML::Element.new(:name<NewElem>);
  =end code
Currently, the only tied methods are `push`, `pop` and `ASSIGN-POS`.


=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod

