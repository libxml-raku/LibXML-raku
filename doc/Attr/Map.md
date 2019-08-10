NAME
====

LibXML::Attr::Map - LibXML Class for Mapped Attributes

SYNOPSIS
========

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
    $atts.setNamedItem('style', 'fontweight: bold');
    my LibXML::Attr $style = $atts.getNamedItem('style');
    $atts.removeNamedItem('style');

DESCRIPTION
===========

This class is roughly equivalent to the W3C DOM NamedNodeMap and (Perl 5's XML::LibXML::NamedNodeMap). This implementation currently limits their use to manipulation of an element's attributes.

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

METHODS
=======

ns($url)
--------

This method presents a view of attributes collated by namespace URL. Any attributes that don't have a namespace are stored with a key of `''`.

    use LibXML;
    use LibXML::Attr;
    use LibXML::Attr::Map;
    use LibXML::Element;

    my $doc = LibXML.load(q:to<EOF>);
    <foo
      att1="AAA" att2="BBB"
      xmlns:x="http://myns.org" x:att3="CCC"
    />
    EOF

    my LibXML::Element $node = $doc.root;
    my LibXML::Attr::Map $atts = $node.attributes;

    say $atts.keys.sort;  # att1 att2 x:att3
    say $atts.ns(:!uri).keys;  # att1 att2
    say $atts.ns(:uri<'http://myns.org'>).keys; # att3
    my LibXML::Attr $att3 = $atts.ns('http://myns.org')<att3>;
    # assign to a new namespace
    my $foo-bar = $atts.ns('http://www.foo.com/')<bar> = 'baz';

  * keys, pairs, kv, elems, values, list

    Similar to the equivalent [Hash](https://docs.perl6.org/type/Hash) methods.

  * setNamedItem

        $map.setNamedItem($new_node)

    Adds or replaces node with the same name as `$new_node `.

  * removeNamedItem

        $map.removeNamedItem($name)

    Remove the item with the name `$name `.

  * getNamedItemNS

        my LibXML::Attr $att = $map.getNamedItemNS($uri, $name);

    `$map.getNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}`.

  * setNamedItemNS

        $map.setNamedItem($uri, $new_node)

    Assigns $new_node name space to $uri. Adds or replaces an nodes same local name as `$new_node `.

  * removeNamedItemNS

        $map.removeNamedItemNS($uri, $name);

    `$map.removedNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}:delete`.

