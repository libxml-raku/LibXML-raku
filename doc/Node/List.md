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

