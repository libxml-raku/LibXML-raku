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
            die "unexpected node of type {$class.WHAT.perl} in node-set"
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
            for self.Array {
                if $!deref && .nodeType == XML_ELEMENT_NODE {
                    deref(%h, .childNodes);
                    deref(%h, .properties);
                }
                else {
                    (%h{.xpath-key} //= LibXML::Node::Set.new: :deref).add: $_;
                }
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
    multi method delete(UInt $pos) is also<DELETE-POS> {
        my $node = self.AT-POS($pos);
        self.delete($_) with $node;
        $node;
    }
    method pop {
        my $node := $!native.pop;
        if $node.defined {
            .{$node.xpath-key}.pop with $!hstore;
        }
        $!lazy ?? self!box($node) !! @!store.pop;
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
    method can($_) { $.of.can($_) || nextsame }
    method FALLBACK($method, |c) {
        if $.first.can($method) {
            $.first."$method"(|c)
        }
        else {
            die X::Method::NotFound.new( :$method, :typename(self.^name) );
        }
    }
}

=begin pod
=head1 NAME

LibXML::Node::Set - LibXML Class for XPath Node Collections

=head1 SYNOPSIS

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
  ...

=head1 DESCRIPTION

This class is commonly used for handling result sets from XPath queries. It performs the Iterator role, which enables:

   for $elem.findnodes($path) {...}
   my LibXML::Item @nodes = $elem.findnodes($xpath);

=head1 METHODS

=begin item
new

    my LibXML::Node::Set $nodes .= new: :$native, :deref;

Options:
    =begin item
    `xmlNodeSet :$native`

    An optional native node-set struct.
    Note: Please use this option with care. `xmlNodeSet` objects cannot be reference counted; which means that objects
    cannot be shared between classess. The native xmlNodeSet object is always freed when the LibXML::Node::Set is destroyed. xmlNodeSet objects need to be newly created, or copied from other native objects. Both of the following are OK:

    my xmlNodeSet $native .= new; # create a new object from scratch
    #-OR-
    my xmlNodeSet $native = $other-node-set.native.copy; # take a copy
    my LibXML::Node::Set $nodes .= new: :$native;
    $native = Nil; # best to avoid any further direct access to the native object
    


    =end item

    =begin item
    `Bool :deref`

    Dereference Elements to their constituant child nodes and attributes. For example:
    
      my LibXML::Document $doc .= parse("example/dromeds.xml");
      # without dereferencing
      my LibXML::Node::Set $species = $doc.findnodes("dromedaries/species");
      say $species.keys; # (species)
      # with dereferencing
      $species = $doc.findnodes("dromedaries/species", :deref);
      #-OR-
      $species = $doc<dromedaries/species>; # The AT-KEY method sets the :deref option
      say $species.keys; # disposition text() humps @name)

    The dereference method is used by the node AT-KEY and Hash methods.

    =end item

Creates a new node set object. Options are:

=end item

=begin item
elems

Returns the number of nodes in the set.
=end item

=begin item
AT-POS

    for 0 ..^ $node-set.elems {
        my $item = $node-set[$_]; # or: $node-set.AT-POS($_);
        ...
    }
Positional interface into the node-set
=end item

=begin item
AT-KEY

    my LibXML::Node::Set $a-nodes = $node-set<a>;
    my LibXML::Node::Set $b-atts = $node-set<@b>;
    my LibXML::Text @text-nodes = $node-set<text()>;

This is an associative interface to node-sets for subetting by element name, attribute name (`@name`)], or by node type, e.g. `text()`, `comment()`, processing-instruction()`.
=end item

=begin item
add($node)

Adds a node to the set.
=end item

=begin item
delete($node)

Deletes a given node from the set.

Note: this is O(n) and will be slower as node-set size increases.
=end item

=begin item
pop

    my LibXML::Item $node = $node-set.pop;

Removes the last item from the set.
=end item

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
