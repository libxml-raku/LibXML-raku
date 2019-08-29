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
    $node-set.push: $elem;

    my LibXML::Item @items = $node-set;
    for $node-set -> LibXML::Item $item { ... }
    for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

    my LibXML::Node::Set %nodes-by-tag-name = $node-set.Hash;
    ...

DESCRIPTION
===========

This class is commonly used for handling result sets from XPath queries.

METHODS
=======

