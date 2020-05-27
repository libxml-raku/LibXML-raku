class LibXML::Namespace
-----------------------

LibXML Namespace implementation

Synopsis
--------

    use LibXML::Namespace;
    my LibXML::Namespace $ns .= new(:$URI, :$prefix);
    say $ns.nodeName();
    say $ns.name();
    my Str $localname = $ns.localname();
    say $ns.getValue();
    say $ns.value();
    my Str $known-uri = $ns.getNamespaceURI();
    my Str $known-prefix = $ns.prefix();
    $key = $ns.unique-key();

Description
-----------

Namespace nodes are returned by both $element.findnodes('namespace::foo') or by $node.getNamespaces().

The namespace node API is not part of any current DOM API, and so it is quite minimal. It should be noted that namespace nodes are *not* a sub class of [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node), however Namespace nodes act a lot like attribute nodes (both perform the [LibXML::Item](https://libxml-raku.github.io/LibXML-raku/Item) role). Similarly named methods return what you would expect if you treated the namespace node as an attribute.

Methods
-------

### method new

    method new(Str:D :$URI!, NCName :$prefix, LibXML::Node :$node)
        returns LibXML::Namespace

Creates a new Namespace node. Note that this is not a 'node' as an attribute or an element node. Therefore you can't do call all [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) Functions. All functions available for this node are listed below.

Optionally you can pass the prefix to the namespace constructor. If `:$prefix` is omitted you will create a so called default namespace. Note, the newly created namespace is not bound to any document or node, therefore you should not expect it to be available in an existing document.

### method declaredURI

```perl6
method declaredURI() returns Str
```

Returns the URI for this namespace

### method declaredPrefix

```perl6
method declaredPrefix() returns LibXML::Types::NCName
```

Returns the prefix for this namespace

### method nodeName

```perl6
method nodeName() returns Str
```

Returns "xmlns:prefix", where prefix is the prefix for this namespace.

### method name

Alias for nodeName()

### method unique-key

```perl6
method unique-key() returns Str
```

Return a unique key for the namespace

This method returns a key guaranteed to be unique for this namespace, and to always be the same value for this namespace. Two namespace objects return the same key if and only if they have the same prefix and the same URI. The returned key value is useful as a key in hashes.

### method getNamespaceURI

```perl6
method getNamespaceURI() returns Str
```

Returns the string "http://www.w3.org/2000/xmlns/"

### method prefix

```perl6
method prefix() returns Str
```

Returns the string "xmlns"

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

