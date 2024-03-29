[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Node](https://libxml-raku.github.io/LibXML-raku/Node)
 :: [List](https://libxml-raku.github.io/LibXML-raku/Node/List)

class LibXML::Node::List
------------------------

LibXML Sibling Node Lists

Synopsis
--------

    use LibXML::Node::List;
    my LibXML::Node::List $node-list, $att-list;

    $att-list = $elem.attributes;
    $node-list = $elem.childNodes;
    $node-list.push: $elem;

    for $node-list -> LibXML::Node $item { ... }
    for ^$node-set.elems { my $item = $node-set[$_]; ... }

    my LibXML::Node::Set %nodes-by-xpath-name = $node-list.Hash;
    # ...

Description
-----------

This class is used for traversing child nodes or attribute lists.

Unlike node-sets, the list is tied to the DOM and can be used to update nodes.

    # replace 4th child
    $node-list[3] = LibXML::TextNode.new :content("Replacement Text");
    # remove last child
    my $deleted-node = $node-set.pop;
    # append a new child element
    $node-set.push: LibXML::Element.new(:name<NewElem>);

Currently, the only tied methods are `push`, `pop` and `ASSIGN-POS`.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

