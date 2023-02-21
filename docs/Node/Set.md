[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Node](https://libxml-raku.github.io/LibXML-raku/Node)
 :: [Set](https://libxml-raku.github.io/LibXML-raku/Node/Set)

class LibXML::Node::Set
-----------------------

LibXML XPath Node Collections

Synopsis
--------

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

Description
-----------

This class is commonly used for handling result sets from XPath queries or DOM navigation methods. It performs the Iterator role, which enables:

    for $elem.findnodes($path) {...}
    my LibXML::Item @nodes = $elem.findnodes($xpath);

Methods
-------

### method new

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

### method elems

    method elems() returns UInt

Returns the number of nodes in the set.

### method AT-POS

    method AT-POS(UInt) returns LibXML::Item

    for ^$node-set.elems {
        my $item = $node-set[$_]; # or: $node-set.AT-POS($_);
        ...
    }

Positional interface into the node-set

### method AT-KEY

    method AT-KEY(Str $expr) returns LibXML::Node::Set
    my LibXML::Node::Set $a-nodes = $node-set<a>;
    my LibXML::Node::Set $b-atts = $node-set<@b>;
    my LibXML::Text @text-nodes = $node-set<text()>;

This is an associative interface to node sub-sets grouped by element name, attribute name (`@name`), or by node type, e.g. `text()`, `comment()`, processing-instruction()`.

### method add (alias push)

    method add(LibXML::Item $node) returns LibXML::Item

Adds a node to the set.

### method pop

    method pop() returns LibXML::Item

Removes the last item from the set.

### method delete

    multi method delete(LibXML::Item $node) returns LibXML::Item
    multi method delete(UInt $pos) returns LibXML::Item

Deletes a given node from the set.

Note: this is O(n) and will be slower as node-set size increases.

### method reverse

    # process nodes in ascending order
    for $node.find('ancestor-or-self::*').reverse { ... }

Reverses the elements in the node-set

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

