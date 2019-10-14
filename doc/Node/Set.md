NAME
====

LibXML::Node::Set - LibXML Class for XPath Node Collections

SYNOPSIS
========

    use LibXML::Node::Set;
    my LibXML::Node::Set $node-set;

    $node-set = $elem.childNodes;
    $node-set = $elem.findnodes($xpath);
    $node-set .= new;
    $node-set.add: $elem;

    my LibXML::Item @items = $node-set;
    for $node-set -> LibXML::Item $item { ... }

    my LibXML::Node::Set %nodes-by-tag-name = $node-set.Hash;
    ...

DESCRIPTION
===========

This class is commonly used for handling result sets from XPath queries. It performs the Iterator role, which enables:

    for $elem.findnodes($path) {...}
    my LibXML::Item @nodes = $elem.findnodes($xpath);

METHODS
=======

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

        This is an associative interface to node-sets for subetting by element name, attribute name (`@name`)], or by node type, e.g. `text()`, `comment()`, processing-instruction()`.

  * add($node)

    Adds a node to the set.

  * delete($node)

    Deletes a given node from the set.

    Note: this is O(n) and will be slower as node-set size increases.

  * pop

        my LibXML::Item $node = $node-set.pop;

    Removes the last item from the set.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

