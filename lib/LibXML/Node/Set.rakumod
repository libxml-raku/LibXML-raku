#| LibXML XPath Node Collections
class LibXML::Node::Set does Iterable does Iterator does Positional {
    use LibXML::Enums;
    use LibXML::Native;
    use LibXML::Item :box-class;
    use Method::Also;

    has Any:U $.of = LibXML::Item;
    has xmlNodeSet $.native;
    has UInt $!idx = 0;
    has @!store;
    has Hash $!hstore;
    has Bool $!lazy = True;
    has Bool $.deref;

    submethod TWEAK {
        $!native //= xmlNodeSet.new;
        .Reference given $!native;
    }
    submethod DESTROY {
        .Unreference with $!native;
    }
    method !box(itemNode $elem) {
        do with $elem {
            my $class := box-class(.type);
            die "unexpected node of type {$class.WHAT.perl} in {$!of.perl} node-set"
               unless $class ~~ $!of;

            $class.box: .delegate;
        } // $!of;
    }
    method elems is also<size Numeric> { $!native.nodeNr }
    method Array handles<List list values map grep> {
        if $!lazy {
            $!idx = 0;
            @!store = self;
            $!lazy = False;
        }
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
    multi method AT-POS(UInt:D $pos where !$!lazy) { @!store[$pos] }
    multi method AT-POS(UInt:D $pos where $_ >= $!native.nodeNr) { $!of }
    multi method AT-POS(UInt:D $pos) is default {
        self!box: $!native.nodeTab[$pos];
    }
    method add(LibXML::Item:D $node) is also<push> {
        @!store.push: $_ unless $!lazy;
        .{$node.xpath-key}.push: $node with $!hstore;
        $!native.push: $node.native.ItemNode;
        $node;
    }
    method pop {
        my $node := $!native.pop;
        if $node.defined {
            .{$node.xpath-key}.pop with $!hstore;
        }
        $!lazy ?? self!box($node) !! @!store.pop;
    }
    multi method delete(UInt $pos) is also<DELETE-POS> {
        my $node = self.AT-POS($pos);
        self.delete($_) with $node;
        $node;
    }
    multi method delete(LibXML::Item:D $node) {
        my UInt $idx := $!native.delete($node.native.ItemNode);
        if $idx >= 0 {
            @!store.slice($idx, 1) unless $!lazy;
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
        @!store .= reverse unless $!lazy;
        $!hstore = Nil;
        self;
    }
    method iterator {
        $!idx = 0;
        self;
    }
    method pull-one {
        if $!native.defined && $!idx < $!native.nodeNr {
            self.AT-POS($!idx++);
        }
        else {
            IterationEnd;
        }
    }
    method ast { self.Array.map(*.ast) }
}

=begin pod

=head2 Synopsis

  =begin code :lang<raku>
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
  =end code

=head2 Description

This class is commonly used for handling result sets from XPath queries. It performs the Iterator role, which enables:
    =begin code :lang<raku>
    for $elem.findnodes($path) {...}
    my LibXML::Item @nodes = $elem.findnodes($xpath);
    =end code

=head2 Methods

    =head3 method new

    =begin code :lang<raku>
    method new(xmlNodeSet :$native, Bool :$deref) returns LibXML::Node::Set
    =end code

    =para
    For example:
    =begin code :lang<raku>
    my xmlNodeSet $native .= new; # create a new object from scratch
    #-OR-
    my xmlNodeSet $native = $other-node-set.native.copy; # take a copy
    my LibXML::Node::Set $nodes .= new: :$native;
    $native = Nil; # best to avoid any further direct access to the native object
    =end code

    The `:deref` option dereferences elements to their constituant child nodes and attributes. For example:
    =begin code :lang<raku>    
      my LibXML::Document $doc .= parse("example/dromeds.xml");
      # without dereferencing
      my LibXML::Node::Set $species = $doc.findnodes("dromedaries/species");
      say $species.keys; # (species)
      # with dereferencing
      $species = $doc.findnodes("dromedaries/species", :deref);
      #-OR-
      $species = $doc<dromedaries/species>; # The AT-KEY method sets the :deref option
      say $species.keys; # disposition text() humps @name)
    =end code
    `:deref` is used by the node AT-KEY and Hash methods.

    =head3 method elems
    =begin code :lang<raku>
    method elems() returns UInt
    =end code
    =para Returns the number of nodes in the set.

    =head3 method AT-POS
    =begin code :lang<raku>
    method AT-POS(UInt) returns LibXML::Item

    for 0 ..^ $node-set.elems {
        my $item = $node-set[$_]; # or: $node-set.AT-POS($_);
        ...
    }
    =end code
    =para Positional interface into the node-set

    =head3 method AT-KEY
    =begin code :lang<raku>
    method AT-KEY(Str $expr) returns LibXML::Node::Set
    my LibXML::Node::Set $a-nodes = $node-set<a>;
    my LibXML::Node::Set $b-atts = $node-set<@b>;
    my LibXML::Text @text-nodes = $node-set<text()>;
    =end code
    =para This is an associative interface to node sub-sets grouped by element name, attribute name (`@name`),
    or by node type, e.g. `text()`, `comment()`, processing-instruction()`.


    =head3 method add (alias push)
    =begin code :lang<raku>
    method add(LibXML::Item $node) returns LibXML::Item
    =end code
    =para Adds a node to the set.

    =head3 method pop
    =begin code :lang<raku>
    method pop() returns LibXML::Item
    =end code
    Removes the last item from the set.

    =head3 method delete
    =begin code :lang<raku>
    multi method delete(LibXML::Item $node) returns LibXML::Item
    multi method delete(UInt $pos) returns LibXML::Item
    =end code
    =para
    Deletes a given node from the set.

    Note: this is O(n) and will be slower as node-set size increases.

    =head3 method reverse
    =begin code :lang<raku>
    # process nodes in ascending order
    for $node.find('ancestor-or-self::*').reverse { ... }
    =end code
    Reverses the elements in the node-set

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
