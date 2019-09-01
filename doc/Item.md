NAME
====

LibXML::Item - LibXML Nodes and Namespaces interface role

SYNOPSIS
========

    use LibXML::Item;
    for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
       when LibXML::Namespace { say "namespace: " ~ .Str }
       when LibXML::Attr      { say "attribute: " ~ .Str }
    }

DESCRIPTON
==========

LibXML::Item is a role performed by LibXML::Namespace and LibXML::Node.

This is a containing role for XPath queries with may return either namespaces or other nodes.

The LibXML::Namespace class is distinct from LibXML::Node classes. It cannot itself contain namespaces and lacks parent or child nodes.

Both nodes and namespaces support the following common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Please see [LibXML::Node](LibXML::Node) and [LibXML::Namespace](LibXML::Namespace).

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

