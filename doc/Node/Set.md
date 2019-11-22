NAME
====

LibXML::Node::Set - LibXML Class for XPath Node Collections

SYNOPSIS
========

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

DESCRIPTION
===========

This class is commonly used for handling result sets from XPath queries. It performs the Iterator role, which enables:

    for $elem.findnodes($path) {...}
    my LibXML::Item @nodes = $elem.findnodes($xpath);

METHODS
=======

  * new

        my LibXML::Node::Set $nodes .= new: :$native, :deref;

    Options:

      * `xmlNodeSet :$native`

        An optional native node-set struct. Note: Please use this option with care. `xmlNodeSet` objects cannot be reference counted; which means that objects cannot be shared between classess. The native xmlNodeSet object is always freed when the LibXML::Node::Set is destroyed. xmlNodeSet objects need to be newly created, or copied from other native objects. Both of the following are OK:

        my xmlNodeSet $native .= new; # create a new object from scratch #-OR- my xmlNodeSet $native = $other-node-set.native.copy; # take a copy my LibXML::Node::Set $nodes .= new: :$native; $native = Nil; # best to avoid any further direct access to the native object

      * `Bool :deref`

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

    Creates a new node set object. Options are:

  * elems

    Returns the number of nodes in the set.

  * AT-POS

        for 0 ..^ $node-set.elems {
            my $item = $node-set[$_]; # or: $node-set.AT-POS($_);
            ...
        }

    Positional interface into the node-set

  * AT-KEY

        my LibXML::Node::Set $a-nodes = $node-set<a>;
        my LibXML::Node::Set $b-atts = $node-set<@b>;
        my LibXML::Text @text-nodes = $node-set<text()>;

    This is an associative interface to node-sets for sub-sets grouped by element name, attribute name (`@name`)], or by node type, e.g. `text()`, `comment()`, processing-instruction()`.

  * add($node)

    Adds a node to the set.

  * delete($node)

    Deletes a given node from the set.

    Note: this is O(n) and will be slower as node-set size increases.

  * pop

        my LibXML::Item $node = $node-set.pop;

    Removes the last item from the set.

  * reverse

        # process nodes in ascending order
        for $node.find('ancestor-or-self::*').reverse { ... }

    Reverses the elements in the node-set

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

