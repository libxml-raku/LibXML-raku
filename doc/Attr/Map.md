NAME
====

LibXML::Attr::Map - LibXML Class for Mapped Attributes

SYNOPSIS
========

    use LibXML::Attr::Map;
    use LibXML::Document;
    use LibXML::Element;
    my LibXML::Document $doc .= parse('<foo att1="AAA" att2="BBB">');
    my LibXML::Element $node = $doc.root;
    my LibXML::Attr::Map $atts = $node.attributes;

    say $atts.keys.sort;  # att1 att2
    say $atts<att1>.Str ; # AAA
    say $atts<att1>.gist; # att1="AAA"
    $atts<att2>:delete;
    $atts<att3> = "CCC";
    say $node.Str; # <foo att1="AAA" att3="CCC">

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

    $atts.setNamedItem('style', 'fontweight: bold');
    my LibXML::Attr $style = $attr.getNamedItem('style');
    $atts.removeNamedItem('style');

Namespaces
----------

Attributes with namespaces are stored in a nested, map under the namespace's URL.

    <foo
      att1="AAA" att2="BBB"
      xmlns:x="http://myns.org" x:att3="CCC"
    />
    EOF

    my LibXML::Element $node = $doc.root;
    my LibXML::Attr::Map $atts = $node.attributes;

    say $atts.keys.sort;  # att1 att2 http://myns.org
    say $atts<http://myns.org>.keys; # att3
    my LibXML::Attr $att3 = $atts<http://myns.org><att3>;
    # assign to a new namespace
    my $foo-bar = $attrs<http://www.foo.com/><bar> = 'baz';

The `:!ns` option filters out any attributes with qaulified namedspaces:

    my LibXML::Attr::Map $atts = $node.attributes: :!ns;
    say $atts.keys.sort;  # att1 att2

METHODS
=======

  * keys, pairs, kv, elems, values, list

    Similar to the equivalent [Hash](https://docs.perl6.org/type/Hash) methods.

  * setNamedItem

        $map.setNamedItem($new_node)

    Sets the node with the same name as `$new_node ` to `$new_node `.

  * removeNamedItem

        $map.removeNamedItem($name)

    Remove the item with the name `$name `.

  * getNamedItemNS

        my LibXML::Attr $att = $map.getNamedItemNS($uri, $name);

    `$map.getNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}`.

  * setNamedItemNS

    *Not implemented yet. *. 

  * removeNamedItemNS

        $map.removeNamedItemNS($uri, $name);

    `$map.removedNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}:delete`.

