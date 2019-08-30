NAME
====

LibXML::Node::List - LibXML Class for Sibling Node Lists

SYNOPSIS
========

    use LibXML::Node::List;
    my LibXML::Node::List $node-list, $att-list;

    $att-list = $elem.attributes;
    $node-list = $elem.childNodes;
    $node-list.push: $elem;

    for $node-list -> LibXML::Node $item { ... }
    for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

    my LibXML::Node::Set %nodes-by-tag-name = $node-list.Hash;
    ...

DESCRIPTION
-----------

This class is used for traversing child nodes or attribute lists.

Unlike node-sets, the list is tied to the DOM and can be used to update nodes.

    $node-set[3] = LibXML::TextNode.new :content("Replacement Text");
    my $deleted-node = $node-set.pop;
    $node-set.push: LibXML::Element.new(:name<NewElem>);

Currently, the only tied methods are `push`, `pop` and `ASSIGN-POS`.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, Shlomi Fish, Tobias Leich, Xliff, David Warring

VERSION
=======

2.0200

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

