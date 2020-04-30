NAME
====

LibXML::Attr::Map - LibXML Class for Mapped Attributes

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

This class is roughly equivalent to the W3C DOM NamedNodeMap and (Perl 5's XML::LibXML::NamedNodeMap). This implementation currently limits their use to manipulation of an element's attributes.

It presents a tied hash-like mapping of attributes to attribute names.

Updating Attributes
-------------------

Attributes can be created, updated or deleted associatively:

```raku
my LibXML::Attr::Map $atts = $node.attributes;
$atts<style> = 'fontweight: bold';
my LibXML::Attr $style = $atts<style>;
$atts<style>:delete; # remove the style
```

There are also some DOM (NamedNodeMap) compatible methods:

```raku
my LibXML::Attr $style .= new: :name<style>, :value('fontweight: bold');
$atts.setNamedItem($style);
$style = $atts.getNamedItem('style');
$atts.removeNamedItem('style');
```

METHODS
=======

  * keys, pairs, kv, elems, values, list

    Similar to the equivalent Raku Hash methods.

  * setNamedItem

    ```raku
    $map.setNamedItem($new_node)
    ```

    Adds or replaces node with the same name as `$new_node `.

  * removeNamedItem

    ```raku
    $map.removeNamedItem($name)
    ```

    Remove the item with the name `$name `.

  * getNamedItemNS

    ```raku
     my LibXML::Attr $att = $map.getNamedItemNS($uri, $name);
    ```

    `$map.getNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}`.

  * setNamedItemNS

    ```raku
    $map.setNamedItem($uri, $new_node)
    ```

    Assigns $new_node name space to $uri. Adds or replaces an nodes same local name as `$new_node `.

  * removeNamedItemNS

    ```raku
    $map.removeNamedItemNS($uri, $name);
    ```

    `$map.removedNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}:delete`.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

