use LibXML::Attr;
use LibXML::Enums;
use LibXML::Node;
use LibXML::Native;
use LibXML::Types :NCName, :QName;
use NativeCall;

class LibXML::Attr::Map {...}

# namespace aware version of LibXML::Attr::Map
class LibXML::Attr::MapNs does Associative {
    trusts LibXML::Attr::Map;
    has LibXML::Node $.node;
    has Str:D $.uri is required;
    has Hash[LibXML::Attr:D] $.name-store is required;
    has LibXML::Attr:D %!local-store{NCName}  handles<AT-KEY EXISTS-KEY Numeric keys pairs kv elems list values List>;

    method !bind(LibXML::Attr:D $att) {
        %!local-store{$att.localname} = $att;
        $!name-store{$att.nodeName} = $att;
        $att;
    }
    method !unbind(LibXML::Attr:D $att) {
        %!local-store{$att.localname}:delete;
        $!name-store{$att.nodeName}:delete;
        $att;
    }

    multi method ASSIGN-KEY(QName $name, Str() $val) {
        $!node.requireNamespace($!uri)
            if $!uri && $name ~~ NCName;
        my LibXML::Attr $att = $!node.setAttributeNS($!uri, $name, $val);
        self!bind($_) with $att;
    }

    method DELETE-KEY(NCName:D $local-name) {
        with %!local-store{$local-name} -> $att {
            $!node.removeAttributeNode($att);
            self!unbind($att);
        }
        else {
            LibXML::Attr;
        }
    }
}

class LibXML::Attr::Map does Associative {
    has LibXML::Node $.node;
    has xmlNs %!ns-map;
    has LibXML::Attr:D %.name-store handles <AT-KEY EXISTS-KEY Numeric keys pairs kv elems>;
    has LibXML::Attr::MapNs %!ns;

    submethod TWEAK() {
        self.sync();
    }

    method sync {
        %!ns-map = ();
        %!name-store = ();
        %!ns = ();

        with $!node.native.properties -> domNode $prop is copy {
            my LibXML::Node $doc = $!node.doc;
            require LibXML::Attr;
            while $prop.defined {
                if $prop.type == XML_ATTRIBUTE_NODE {
                    my xmlAttr $native := nativecast(xmlAttr, $prop);
                    my $att := LibXML::Attr.new: :$native, :$doc;
                    self!bind($att);
                }

                $prop = $prop.next;
            }
        }
    }

    # merge in new attributes;
    method ASSIGN-KEY(QName:D $name, Str:D $value) is default {
        $!node.setAttribute($name, $value);
        with $!node.getAttributeNode($name) {
            # bind if we ended up with an attribute (didn't get caught
            # up in LibXML::DOM::Native::Element 'xmlns' shenanigans)
            self!bind($_);
        }
    }

    method DELETE-KEY(QName:D $key) {
        with self.AT-KEY($key) -> $att {
            self.removeAttributeNode($att);
        }
    }

    multi method ns(Str $uri is copy) {
        $uri //= '';
        %!ns{$uri} //= LibXML::Attr::MapNs.new(:$uri, :$!node, :%!name-store);
    }
    multi method ns is default { %!ns }

    method !bind(LibXML::Attr:D $att) {
        my QName:D $name = $att.name;
        my Str $uri = $att.getNamespaceURI // '';

        if !$uri {
            my ($prefix, $local-name) = $name.split(':', 2);
            if $local-name {
                # vivify the namespace from the prefix
                with $!node.doc {
                    %!ns-map{$prefix} = .native.SearchNs($!node.native, $prefix)
                        unless %!ns-map{$prefix}:exists;

                    with %!ns-map{$prefix} -> $ns {
                        $uri = $ns.href;
                        $att.setNamespace($uri, $prefix);
                    }
                }
            }
        }

        $.ns($uri)!LibXML::Attr::MapNs::bind($att);
    }

    method !unbind(LibXML::Attr:D $att) {
        my Str $uri = $att.getNamespaceURI // '';
        $.ns($uri)!LibXML::Attr::MapNs::unbind($att);
        $att;
    }

    method removeAttributeNode(LibXML::Attr:D $att) {
        with $!node.removeAttributeNode($att) {
            self!unbind($_);
        }
        else {
            LibXML::Attr;
        }
    }

    # DOM Support
    method setNamedItem(LibXML::Attr:D $att) {
        $!node.setAttributeNode($att);
        self!bind($att);
    }
    method getNamedItem(QName:D $name) {
        self{$name};
    }
    method removeNamedItem(QName:D $name) {
        self{$name}:delete;
    }

    method setNamedItemNS(Str $uri, LibXML::Attr:D $att) {
        with $uri {
            unless $att.getNamespaceURI ~~ $_ {
                # changing URI and maybe prefix
                self!unbind($att);
                my $prefix = $!node.requireNamespace($_);
                $att.setNamespace($_, $prefix);
            }
        }
        $!node.setAttributeNodeNS($att);
        self!bind($att);
    }
    method getNamedItemNS(Str $uri, NCName:D $local-name) {
        .{$local-name} with %!ns{$uri // ''};
    }

    method removeNamedItemNS(Str $uri, NCName:D $local-name) {
        .{$local-name}:delete with %!ns{$uri // ''};
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
  $atts.setNamedItem('style', 'fontweight: bold');
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

=head2 ns($url)

This method presents a view of attributes collated by namespace URL. Any
attributes that don't have a namespace are stored with a key of `''`.

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
  say $atts.ns('').keys;  # att1 att2
  say $atts.ns('http://myns.org').keys; # att3
  my LibXML::Attr $att3 = $atts.ns('http://myns.org')<att3>;
  # assign to a new namespace
  my $foo-bar = $atts.ns('http://www.foo.com/')<bar> = 'baz';

=begin item1
keys, pairs, kv, elems, values, list

Similar to the equivalent L<Hash|https://docs.perl6.org/type/Hash> methods.

=end item1

=begin item1
setNamedItem

  $map.setNamedItem($new_node)

Sets the node with the same name as C<<<<<< $new_node >>>>>> to C<<<<<< $new_node >>>>>>.

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

I<<<<<< Not implemented yet. >>>>>>. 

=end item1

=begin item1
removeNamedItemNS

  $map.removeNamedItemNS($uri, $name);

C<$map.removedNamedItemNS($uri,$name)> is similar to C<$map{$uri}{$name}:delete>.

=end item1

=end pod



