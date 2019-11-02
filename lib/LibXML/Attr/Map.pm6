use LibXML::Attr;

class LibXML::Attr::Map does Associative {
    use LibXML::Types :QName, :NCName;
    has LibXML::Node $.node handles<removeAttributeNode>;
    use Method::Also;

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

    method elems is also<Numeric> { $!node.findvalue('count(@*)') }
    method Hash handles<keys pairs values kv> {
        my % = $!node.findnodes('@*').Array.map: {
            .tagName => $_;
        }
    }


    # DOM Support
    method setNamedItem(LibXML::Attr:D $att) {
        $!node.setAttributeNodeNS($att);
    }
    method getNamedItem(QName:D $name) {
        self{$name};
    }
    method removeNamedItem(QName:D $name) {
        self{$name}:delete;
    }

    method setNamedItemNS(Str $new-uri, LibXML::Attr:D $att) {
        my $old-uri = $att.getNamespaceURI;
        if $new-uri {
            unless $old-uri ~~ $new-uri {
                my $prefix = $!node.requireNamespace($new-uri);
                $att.setNamespace($new-uri, $prefix);
            }
        }
        elsif $old-uri {
            $att.clearNamespace($old-uri);
        }
        $!node.setAttributeNodeNS($att);
    }

    method getNamedItemNS(Str $uri, NCName:D $name) {
        my $query = "\@*[local-name()='$name']";
        $query ~= "[namespace-uri()='$_']" with $uri;
        LibXML::Attr.box: self.domXPathSelectStr($query);
    }

    method removeNamedItemNS(Str $uri, NCName:D $name) {
        do with $.getNamedItemNS($name) { .unlink } // LibXML::Attr;
    }
}

=begin pod
=head1 NAME

LibXML::Attr::Map - LibXML Class for Mapped Attributes

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class is roughly equivalent to the W3C DOM NamedNodeMap and (Perl 5's XML::LibXML::NamedNodeMap). This implementation currently limits their use to manipulation of an element's attributes.

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

=head1 METHODS

=begin item1
keys, pairs, kv, elems, values, list

Similar to the equivalent L<Hash|https://docs.perl6.org/type/Hash> methods.

=end item1

=begin item1
setNamedItem

  $map.setNamedItem($new_node)

Adds or replaces node with the same name as C<<<<<< $new_node >>>>>>.

=end item1

=begin item1
removeNamedItem

  $map.removeNamedItem($name)

Remove the item with the name C<<<<<< $name >>>>>>.

=end item1

=begin item1
getNamedItemNS

   my LibXML::Attr $att = $map.getNamedItemNS($uri, $name);

C<$map.getNamedItemNS($uri,$name)> is similar to C<$map{$uri}{$name}>.

=end item1

=begin item1
setNamedItemNS

  $map.setNamedItem($uri, $new_node)

Assigns $new_node name space to $uri. Adds or replaces an nodes same local name as C<<<<<< $new_node >>>>>>.

=end item1

=begin item1
removeNamedItemNS

  $map.removeNamedItemNS($uri, $name);

C<$map.removedNamedItemNS($uri,$name)> is similar to C<$map{$uri}{$name}:delete>.

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod



