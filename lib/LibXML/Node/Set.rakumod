#| LibXML XPath Node Collections
class LibXML::Node::Set does Iterable does Iterator does Positional {
    use LibXML::Enums;
    use LibXML::Raw;
    use LibXML::Item :box-class;
    use Method::Also;

    has Any:U $.of = LibXML::Item;
    has xmlNodeSet $.native;
    has UInt $!idx = 0;
    has @!store;
    has Hash $!hstore;
    has Bool $!reified;
    has Bool $.deref;

    submethod TWEAK {
        $!native //= xmlNodeSet.new;
        .Reference given $!native;
        @!store[$!native.nodeNr - 1] = Mu
            if $!native.nodeNr;
    }
    submethod DESTROY {
        .Unreference with $!native;
    }

    method elems is also<size Numeric> { $!native.nodeNr }
    method Array handles<List list values map grep> {
        self.pull-one until $!reified;
        @!store;
    }
    sub deref(%h, $nodes is raw) {
        for $nodes {
            (%h{.xpath-key} //= LibXML::Node::Set.new: :deref).add: $_
        }
    }
    method Hash handles <AT-KEY keys> {
        $!hstore //= do {
            my LibXML::Node::Set %h = ();
            if $!deref {
                for self.Array {
                    if .nodeType == XML_ELEMENT_NODE {
                        deref(%h, .childNodes);
                        deref(%h, .properties);
                    }
                }
            }
            else {
                deref(%h, self.Array)
            }
            %h;
        }
    }
    method AT-POS(UInt:D $pos) {
        $pos >= $!native.nodeNr
            ?? $!of
            !! (@!store[$pos] //= $!of.box: $!native.nodeTab[$pos]);
    }
    method add(LibXML::Item:D $node) is also<push> {
        fail "node has wrong type {$node.WHAT.perl} for node-set of type: {$!of.WHAT}"
            unless $node ~~ $!of;
        @!store[$!native.nodeNr] = $node;
        .{$node.xpath-key}.push: $node with $!hstore;
        $!native.push: $node.raw.ItemNode;
        $node;
    }
    method pop {
        with $!native.pop -> $node {
            .{$node.xpath-key}.pop with $!hstore;
            do {
                @!store.pop
                    if @!store > $!native.nodeNr
            } // $!of.box: $node;
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
        my UInt $idx := $!native.delete($node.raw.ItemNode);
        if $idx >= 0 {
            @!store.slice($idx, 1) if @!store >= $idx;
            .{$node.xpath-key}.delete with $!hstore;
            $node;
        }
        else {
            $!of;
        }
    }
    method first { self.AT-POS(0) }
    method tail  { my $n := $!native.nodeNr; $n ?? self.AT-POS($n - 1) !! $!of }
    method string-value { do with $.first { .string-value } // Str}
    multi method to-literal( :list($)! where .so ) { self.map({ .string-value }) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Bool { self.defined && self.elems }
    method Str is also<gist> handles <Int Num trim chomp> { $.Array.map(*.Str).join }
    method is-equiv(LibXML::Node::Set:D $_) { ? $!native.hasSameNodes(.native) }
    method reverse {
        $!native.reverse;
        @!store .= reverse if @!store;
        $!hstore = Nil;
        self;
    }
    method iterator {
        $!idx = 0;
        self;
    }
    method pull-one {
        if $!idx < $!native.nodeNr {
            self.AT-POS($!idx++);
        }
        else {
            $!reified = True;
            IterationEnd;
        }
    }
    method ast { self.Array.map(*.ast) }
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

        method new(xmlNodeSet :$native, Bool :$deref) returns LibXML::Node::Set

        my xmlNodeSet $native .= new; # create a new object from scratch
        #-OR-
        my xmlNodeSet $native = $other-node-set.native.copy; # take a copy
        my LibXML::Node::Set $nodes .= new: :$native;
        $native = Nil; # best to avoid any further direct access to the native object

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
