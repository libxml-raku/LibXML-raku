class LibXML::Node::List does Iterable does Iterator {
    use LibXML::Native;
    use LibXML::Node;

    has Bool $.keep-blanks;
    has $.doc is required;
    has anyNode $.native is required handles <string-value>;
    has $!cur;
    has $.of is required;
    has LibXML::Node @!store;
    has Hash $!hstore;
    has Bool $!lazy = True;
    has LibXML::Node $!first; # just to keep the list alive
    has LibXML::Node $.parent;
    method parent { $!parent // $!first.parent // fail "parent not found"; }
    submethod TWEAK {
        $!first = $!of.box: $_ with $!native;
        $!cur = $!native;
    }

    method Array handles<AT-POS elems List list values map grep Numeric> {
        if $!lazy-- {
            $!cur = $!native;
            @!store = self;
        }
        @!store;
    }
    method Hash {
        $!hstore //= do {
            my $set-class := (require ::('LibXML::Node::Set'));
            my %h = ();
            for self.Array {
                (%h{.tagName} //= $set-class.new).push: $_;
            }
            %h;
        }
    }
    method push(LibXML::Node:D $node) {
        $.parent.appendChild($node);
        @!store.push($node) unless $!lazy;
        .{$node.tagName}.push: $node with $!hstore;
        $node;
    } 
    method pop {
        do with self.Array.tail -> LibXML::Node $node {
            @!store.pop;
            .{$node.tagName}.pop with $!hstore;
            $node.unbindNode;
        } // LibXML::Node;
    }
    method ASSIGN-POS(UInt() $pos, LibXML::Node $node) {
        if $pos < $.elems {
            $!hstore = Nil; # invalidate Hash cache
            $.parent.replaceChild($node, $.Array[$pos]);
            @!store[$pos] = $node;
        }
        elsif $pos == $.elems {
            # allow append of tail element
            $.push($node);
        }
        else {
            fail "array index out of bounds";
        }
    }
    multi method to-literal( :list($)! where .so ) { self.map(*.string-value) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Str  { $.to-literal }
    method iterator {
        $!cur = $!native;
        self;
    }
    method pull-one {
        with $!cur -> $this {
            $!cur = $this.next-node($!keep-blanks);
            $!of.box: $this, :$!doc
        }
        else {
            IterationEnd;
        }
    }
    method to-node-set {
        require LibXML::Node::Set;
        my xmlNodeSet:D $native = $!native.list-to-nodeset($!keep-blanks);
        LibXML::Node::Set.new: :$native;
    }
}

=begin pod
=head1 NAME

LibXML::Node::List - LibXML Class for Sibling Node Lists

=head1 SYNOPSIS

  use LibXML::Node::List;
  my LibXML::Node::List $node-list, $att-list;

  $att-list = $elem.attributes;
  $node-list = $elem.childNodes;
  $node-list.push: $elem;

  for $node-list -> LibXML::Node $item { ... }
  for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

  my LibXML::Node::Set %nodes-by-tag-name = $node-list.Hash;
  ...

=head2 DESCRIPTION

This class is used for traversing child nodes or attribute lists.

Unlike node-sets, the list is tied to the DOM and can be used to update
nodes.

  $node-set[3] = LibXML::TextNode.new :content("Replacement Text");
  my $deleted-node = $node-set.pop;
  $node-set.push: LibXML::Element.new(:name<NewElem>);

Currently, the only tied methods are `push`, `pop` and `ASSIGN-POS`.


=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod

