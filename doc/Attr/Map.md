NAME
====

LibXML::Attr::Map - LibXML Class for Mapped Attributes

SYNOPSIS
========

    use LibXML::Attr::Map;
    use LibXML::Document;
    use LibXML::Element;
    my LibXML::Document $doc .= parse(q:to<EOF>);
    <foo
      att1="AAA" att2="BBB"
      xmlns:x="http://myns.org" x:att3="CCC" x:att4="DDD"
    />
    EOF

    my LibXML::Element $root = $doc.root;
    my LibXML::Attr::Map $atts = $root.attributes;

    say $atts.keys.sort;  # att1 att2 http://myns.org
    say $atts<att1>.gist; # att1="AAA"

    say $atts<http://myns.org>.keys.sort; # att3 att4
    my $att3 = $atts<http://myns.org><att3>;

    # create an attribute in a new namespace.
    $atts{'http://ns2.org'}<atts1> = "EEE";

DESCRIPTION
===========

This class is roughly equivalent to the W3C DOM NamedNodeMap and (Perl 5's XML::LibXML::NamedNodeMap). This implementation currently limits their use to manipulation of an element's attributes.

It presents a tied hash-like mapping of attributes to attribute names.

Attributes with namespaces are stored in a nested, map under the namespace's URL.

METHODS
=======

  * keys, pairs, kv, elems, values, list

Similar to the equivalent [Hash](https://docs.perl6.org/type/Hash) methods.

