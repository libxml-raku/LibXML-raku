#| LibXML XPath Node Collections
class LibXML::Node::Set
    does Iterable
    does Positional {

    use LibXML::Enums;
    use LibXML::Raw;
    use LibXML::Raw::HashTable;
    use LibXML::Item;
    use Method::Also;
    use NativeCall;

    has LibXML::Item $.of;
    has Bool $.deref;
    has xmlNodeSet $.raw;
    has $!hstore;

    submethod TWEAK {
        $!raw //= xmlNodeSet.new;
        .Reference given $!raw;
    }
    submethod DESTROY {
        .Unreference with $!raw;
    }

    method elems is also<size Numeric> { $!raw.nodeNr }
    method Seq returns Seq handles<Array list values map grep> {
        my CArray $tab := $!raw.nodeTab;
        (0 ..^ $!raw.nodeNr).map: { $!of.box: $tab[$_] };
    }

    method Hash handles <AT-KEY keys pairs> {
        $!hstore //= do {
            my xmlHashTable:D $raw = $!raw.Hash(:$!deref);
            require LibXML::HashMap::Maker;
            LibXML::HashMap::Maker.(LibXML::Node::Set).new: :$raw;
        }
    }
    method AT-POS(UInt:D $pos) {
        $pos >= $!raw.nodeNr
            ?? $!of
            !! $!of.box($!raw.nodeTab[$pos]);
    }
    method add(LibXML::Item:D $node) is also<push> {
        constant Ref = 1;
        fail "node has wrong type {$node.WHAT.perl} for node-set of type: {$!of.WHAT}"
            unless $node ~~ $!of;
        $!hstore = Nil;
        $!raw.push($node.raw.ItemNode, Ref);
        $node;
    }
    method pop {
        with $!raw.pop -> $node {
            $!hstore = Nil;
            $!of.box: $node;
        }
        else {
            $!of;
        }
    }
    multi method delete(UInt $pos) is also<DELETE-POS> {
        my $node = self.AT-POS($pos);
        self.delete($_) with $node;
        $node;
    }
    multi method delete(LibXML::Item:D $node) {
        my UInt $idx := $!raw.delete($node.raw.ItemNode);
        if $idx >= 0 {
            $!hstore = Nil;
            $node;
        }
        else {
            $!of;
        }
    }
    method first { self.AT-POS(0) }
    method tail  { my $n := $!raw.nodeNr; $n ?? self.AT-POS($n - 1) !! $!of }
    method string-value { do with $.first { .string-value } // Str}
    multi method to-literal( :list($)! where .so ) { self.map({ .string-value }) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Bool { self.defined && self.elems }
    method Str is also<gist> handles <Int Num trim chomp> { $.Array.map(*.Str).join }
    method is-equiv(LibXML::Node::Set:D $_) { ? $!raw.hasSameNodes(.raw) }
    method reverse {
        $!raw.reverse;
        $!hstore = Nil;
        self;
    }
    method ast { self.Array.map(*.ast) }

    method iterator {
        class Iteration does Iterator {
            has UInt $!idx = 0;
            has LibXML::Node::Set $.nodes is required;
            method pull-one {
                if $!idx < $!nodes.raw.nodeNr {
                    $!nodes.AT-POS($!idx++);
                }
                else {
                    IterationEnd;
                }
            }
        }
        Iteration.new: :nodes(self);
    }
}

=begin pod

=head2 Synopsis

  use LibXML::Node::Set;
  my LibXML::Node::Set $node-set;

  $node-set = $elem.childNodes;
  $node-set = $elem.findnodes($xpath, :$deref);
  $node-set = $elem{$xpath}
  $node-set .= new: $deref;
  $node-set.add: $elem;

  my LibXML::Item @items = $node-set;
  for $node-set -> LibXML::Item $item { ... }

  my LibXML::Node::Set %nodes-by-name = $node-set.Hash;
  # ...

=head2 Description

This class is commonly used for handling result sets from XPath queries. It performs the Iterator role, which enables:

    for $elem.findnodes($path) {...}
    my LibXML::Item @nodes = $elem.findnodes($xpath);

=head2 Methods

    =head3 method new

        method new(xmlNodeSet :$raw, Bool :$deref) returns LibXML::Node::Set

        my xmlNodeSet $raw .= new; # create a new object from scratch
        #-OR-
        my xmlNodeSet $raw = $other-node-set.raw.copy; # take a copy
        my LibXML::Node::Set $nodes .= new: :$raw;
        $raw = Nil; # best to avoid any further direct access to the raw object

    The `:deref` option dereferences elements to their constituant child nodes and attributes. For example:

      my LibXML::Document $doc .= parse("example/dromeds.xml");
      # without dereferencing
      my LibXML::Node::Set $species = $doc.findnodes("dromedaries/species");
      say $species.keys; # (species)
      # with dereferencing
      $species = $doc.findnodes("dromedaries/species", :deref);
      #-OR-
      $species = $doc<dromedaries/species>; # The AT-KEY method sets the :deref option
      say $species.keys; # disposition text() humps @name)

    `:deref` is used by the node AT-KEY and Hash methods.

    =head3 method elems

        method elems() returns UInt

    Returns the number of nodes in the set.

    =head3 method AT-POS

        method AT-POS(UInt) returns LibXML::Item

        for 0 ..^ $node-set.elems {
            my $item = $node-set[$_]; # or: $node-set.AT-POS($_);
            ...
        }

    Positional interface into the node-set

    =head3 method AT-KEY

        method AT-KEY(Str $expr) returns LibXML::Node::Set
        my LibXML::Node::Set $a-nodes = $node-set<a>;
        my LibXML::Node::Set $b-atts = $node-set<@b>;
        my LibXML::Text @text-nodes = $node-set<text()>;

    =para This is an associative interface to node sub-sets grouped by element name, attribute name (`@name`),
    or by node type, e.g. `text()`, `comment()`, processing-instruction()`.


    =head3 method add (alias push)

        method add(LibXML::Item $node) returns LibXML::Item

    Adds a node to the set.

    =head3 method pop

        method pop() returns LibXML::Item

    Removes the last item from the set.

    =head3 method delete

        multi method delete(LibXML::Item $node) returns LibXML::Item
        multi method delete(UInt $pos) returns LibXML::Item

    Deletes a given node from the set.

    Note: this is O(n) and will be slower as node-set size increases.

    =head3 method reverse

        # process nodes in ascending order
        for $node.find('ancestor-or-self::*').reverse { ... }

    Reverses the elements in the node-set

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
