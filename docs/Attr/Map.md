[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Attr](https://libxml-raku.github.io/LibXML-raku/Attr)
 :: [Map](https://libxml-raku.github.io/LibXML-raku/Attr/Map)

class LibXML::Attr::Map
-----------------------

LibXML Mapped Attributes

Synopsis
--------

    use LibXML::Attr::Map;
    use LibXML::Document;
    use LibXML::Element;
    my LibXML::Document $doc .= parse('<foo att1="AAA" att2="BBB"/>');
    my LibXML::Element $node = $doc.root;
    my LibXML::Attr::Map $atts = $node.attributes;

    # -- Associative Interface --
    say $atts.keys.sort;  # att1 att2
    say $atts<att1>.Str ; # AAA
    say $atts<att1>.gist; # att1="AAA"
    $atts<att2>:delete;
    $atts<att3> = "CCC";
    say $node.Str; # <foo att1="AAA" att3="CCC"/>

    # -- DOM Interface --
    $atts.setNamedItem('style', 'font-weight: bold');
    my LibXML::Attr $style = $atts.getNamedItem('style');
    $atts.removeNamedItem('style');

Description
-----------

This class is roughly equivalent to the W3C DOM NamedNodeMap (and the Perl XML::LibXML::NamedNodeMap class). This implementation currently limits their use to manipulation of an element's attributes.

It presents a tied hash-like mapping of attributes to attribute names.

Updating Attributes
-------------------

Attributes can be created, updated or deleted associatively:

    my LibXML::Attr::Map $atts = $node.attributes;
    $atts<style> = 'fontweight: bold';
    my LibXML::Attr $style = $atts<style>;
    $atts<style>:delete; # remove the style

There are also some DOM (NamedNodeMap) compatible methods:

    my LibXML::Attr $style .= new: :name<style>, :value('fontweight: bold');
    $atts.setNamedItem($style);
    $style = $atts.getNamedItem('style');
    $atts.removeNamedItem('style');

Methods
-------

### keys, pairs, kv, elems, values, list, AT-KEY, ASSIGN-KEY, DELETE-KEY

Similar to the equivalent Raku Hash methods.

### method setNamedItem

```perl6
method setNamedItem(
    LibXML::Attr:D $att
) returns LibXML::Attr
```

Adds or replaces node with the same name as $att

### method getNamedItem

```perl6
method getNamedItem(
    Str:D $name where { ... }
) returns LibXML::Attr
```

Gets an attribute by name

### method removeNamedItem

```perl6
method removeNamedItem(
    Str:D $name where { ... }
) returns LibXML::Attr
```

Remove the item with the name `$name`

### method setNamedItemNS

```perl6
method setNamedItemNS(
    Str $uri,
    LibXML::Attr:D $att
) returns Mu
```

Assigns $att name space to $uri. Adds or replaces an attribute with the same as `$att`

### method getNamedItemNS

```perl6
method getNamedItemNS(
    Str $uri,
    Str:D $name where { ... }
) returns LibXML::Attr
```

Lookup attribute by namespace and name

`$map.getNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}`.

### method removeNamedItemNS

```perl6
method removeNamedItemNS(
    Str $uri,
    Str:D $name where { ... }
) returns LibXML::Attr
```

Lookup and remove attribute by namespace and name

`$map.removeNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}:delete`.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

