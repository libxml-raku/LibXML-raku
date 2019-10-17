class LibXML::Node::List does Iterable does Iterator {
    use LibXML::Native;
    use LibXML::Node;
    use Method::Also;

    has Bool:D $.keep-blanks = False;
    has $.doc is required;
    has anyNode $.native handles <string-value>;
    has LibXML::Node $!first;
    has anyNode $!cur;
    has $.of is required;
    has int $.idx = 0;
    has LibXML::Node @!store;
    has Hash $!hstore;
    has Bool $!lazy = True;
    has LibXML::Node $.parent is required;

    submethod TWEAK(:$properties) {
        $!native = do given $!parent.native {
            $properties ?? .properties !! .first-child(+$!keep-blanks);
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
            $_ = .next-node($!keep-blanks) with $!cur;
            $!of.box: $!cur, :$!doc;
        }
        default {
            # switch to random access
            self.Array.AT-POS($pos);
        }
    }
    method Hash {
        $!hstore //= do {
            my $set-class := (require ::('LibXML::Node::Set'));
            my %h = ();
            for self.Array {
                (%h{.xpath-key} //= $set-class.new).add: $_;
            }
            %h;
        }
    }

    method push(LibXML::Node:D $node) {
        $.parent.appendChild($node);
        @!store.push($node) unless $!lazy;
        .{$node.xpath-key}.push: $node with $!hstore;
        $node;
    } 
    method pop {
        do with self.Array.tail -> LibXML::Node $node {
            @!store.pop;
            .{$node.xpath-key}.pop with $!hstore;
            $node.unbindNode;
        } // LibXML::Node;
    }
    method ASSIGN-POS(UInt() $pos, LibXML::Node:D $node) {
        if $pos < $.elems {
            $!hstore = Nil; # invalidate Hash cache
            $.parent.replaceChild($node, $.Array[$pos]);
            $!cur = $node.native if $pos == $!idx;
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
    method Str is also<gist> { $.Array.map(*.Str).join }
    method iterator {
        $!cur = $!native;
        self;
    }
    method pull-one {
        with $!cur -> $this {
            $!idx++;
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

  my LibXML::Node::Set %nodes-by-xpath-name = $node-list.Hash;
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

