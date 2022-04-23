#| LibXML Mapped Attributes
unit class LibXML::Attr::Map;

use W3C::DOM;
also does Associative;
also does W3C::DOM::NamedNodeMap;

use LibXML::Attr;
use LibXML::Types :QName, :NCName;
has LibXML::Node $.node handles<removeAttributeNode>;
use Method::Also;

=begin pod
    =head2 Synopsis

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

    =head2 Description

    This class is roughly equivalent to the W3C DOM NamedNodeMap (and the Perl XML::LibXML::NamedNodeMap class). This implementation currently limits their use to manipulation of an element's attributes.

    It presents a tied hash-like mapping of attributes to attribute names.

    =head2 Updating Attributes

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

    =head2 Methods

    =head3 keys, pairs, kv, elems, values, list, AT-KEY, ASSIGN-KEY, DELETE-KEY
    =para Similar to the equivalent Raku Hash methods.
=end pod

multi method AT-KEY(QName:D $name) {
    $!node.getAttributeNode($name);
}

multi method AT-KEY(Str:D $name) is default {
    $!node.findnodes('@' ~ $name)[0];
}

method ASSIGN-KEY(QName:D $name, Str:D $value) {
    $!node.setAttribute($name, $value);
}

method DELETE-KEY(QName:D $key) {
    with self.AT-KEY($key) -> $att {
        self.removeAttributeNode($att);
    }
}

method elems is also<Numeric length> { $!node.findvalue('count(@*)') }
method Hash handles<keys pairs values kv> {
    my % = $!node.findnodes('@*').Array.map: {
        .tagName => $_;
    }
}


# DOM Support

#| Adds or replaces node with the same name as $att
method setNamedItem(LibXML::Attr:D $att --> LibXML::Attr) {
    $!node.setAttributeNodeNS($att);
}

#| Gets an attribute by name
method getNamedItem(QName:D $name --> LibXML::Attr) {
    self{$name};
}

#| Remove the item with the name `$name`
method removeNamedItem(QName:D $name --> LibXML::Attr) {
    self{$name}:delete;
}

#| Assigns $att name space to $uri. Adds or replaces an attribute with the same as `$att`
method setNamedItemNS(Str $uri, LibXML::Attr:D $att) {
    my $old-uri = $att.getNamespaceURI;
    if $uri {
        unless $old-uri ~~ $uri {
            my $prefix = $!node.requireNamespace($uri);
            $att.setNamespace($uri, $prefix);
        }
    }
    elsif $old-uri {
        $att.clearNamespace($old-uri);
    }
    $!node.setAttributeNodeNS($att);
}

#| Lookup attribute by namespace and name
method getNamedItemNS(Str $uri, NCName:D $name --> LibXML::Attr) {
    my $query = "\@*[local-name()='$name']";
    $query ~= "[namespace-uri()='$_']" with $uri;
    &?ROUTINE.returns.box: self.domXPathSelectStr($query);
}
=begin pod
C<$map.getNamedItemNS($uri,$name)> is similar to C<$map{$uri}{$name}>.
=end pod

#| Lookup and remove attribute by namespace and name
method removeNamedItemNS(Str $uri, NCName:D $name --> LibXML::Attr) {
    do with $.getNamedItemNS($name) { .unlink } // LibXML::Attr;
}
=para `$map.removeNamedItemNS($uri,$name)` is similar to `$map{$uri}{$name}:delete`.

=begin pod

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod



