use LibXML::Node :iterate;

unit class LibXML::Element
    is LibXML::Node;

use NativeCall;

use LibXML::Enums;
use LibXML::Native;
use LibXML::Types :QName, :NCName;
use LibXML::Attr;
use LibXML::Namespace;

my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;

multi submethod TWEAK(xmlNode:D :native($)!) { }
multi submethod TWEAK(:doc($doc-obj), QName :$name!, LibXML::Namespace :ns($ns-obj)) {
    my xmlDoc:D $doc = .native with $doc-obj;
    my xmlNs:D $ns = .native with $ns-obj;
    self.native = xmlNode.new: :$name, :$doc, :$ns;
}

multi method new($name, *%o) {
    self.new(:$name, |%o);
}

multi method new(|c) is default { nextsame }

sub iterate-ns(LibXML::Namespace $obj, $start, :$doc = $obj.doc) {
    # follow a chain of .next links.
    my class NodeList does Iterable does Iterator {
        has $.cur;
        method iterator { self }
        method pull-one {
            my $this = $!cur;
            $_ = .next with $!cur;
            with $this -> $node {
                $obj.box: $node, :$doc
            }
            else {
                IterationEnd;
            }
        }
    }.new( :cur($start) );
}

method namespaces {
    iterate-ns(LibXML::Namespace, $.native.nsDef, :$.doc);
}

method !get-attributes {

    class AttrMap {...}
    class AttrMapNs does Associative {
        trusts AttrMap;
        has LibXML::Node $.node;
        has Str:D $.uri is required;
        has LibXML::Attr:D %!store handles <EXISTS-KEY Numeric keys pairs kv elems>;

        method !unlink(Str:D $key) {
            $!node.removeChild($_)
                with %!store{$key}:delete;
        }
        method !store(Str:D $name, LibXML::Attr:D $att) {
            self!unlink($name);
            %!store{$name} = $att;
        }

        method AT-KEY($key) is rw {
            %!store{$key};
        }

        multi method ASSIGN-KEY(Str() $name, Str() $val) {
            self!store($name,  $!node.setAttributeNS($!uri, $name, $val));
        }

        method BIND-KEY(Str() $name, Str() $val) {
            self!unlink($name);
            %!store{$name} := $!node.setAttributeNS($!uri, $name, $val);
        }

        method DELETE-KEY(Str() $name) {
            self!unlink($name);
        }
    }

    class AttrMap does Associative {
        has LibXML::Node $.node;
        has xmlNs %!ns;
        my subset AttrMapNode where LibXML::Attr:D|AttrMapNs:D;
        has AttrMapNode %!store handles <EXISTS-KEY Numeric keys pairs kv elems>;

        submethod TWEAK() {
            with $!node.native.properties -> domNode $prop is copy {
                my LibXML::Node $doc = $!node.doc;
                require LibXML::Attr;
                while $prop.defined {
                    my $uri;
                    if $prop.type == XML_ATTRIBUTE_NODE {
                        my xmlAttr $native := nativecast(xmlAttr, $prop);
                        my $att := LibXML::Attr.new: :$native, :$doc;
                        self!tie-att($att);
                    }

                    $prop = $prop.next;
                }
            }
        }

        method !unlink(Str:D $key) {
            with %!store{$key}:delete {
                 when AttrMapNs {
                     for .keys -> $key {
                         .DELETE-KEY($key);
                     }
                 }
                 when LibXML::Node {
                     $!node.removeAttribute($key)
                 }
            }
        }
        method !store(Str:D $name, AttrMapNode:D $att) {
            self!unlink($name);
            %!store{$name} = $att;
        }

        method AT-KEY($key) is rw {
            Proxy.new(
                FETCH => sub ($) {
                    %!store{$key};
                },
                STORE => sub ($, Hash $ns) {
                    # for autovivication
                    self.ASSIGN-KEY($key, $ns);
                },
            );
        }

        # merge in new attributes;
        multi method ASSIGN-KEY(Str() $uri, AttrMapNs $ns-atts) {
            self!store($ns-atts.uri, $ns-atts);
        }

        multi method ASSIGN-KEY(Str() $uri, Hash $atts) {
            # plain hash; need to coerce
            my AttrMapNs $ns-map .= new: :$!node, :$uri;
            for $atts.pairs {
                $ns-map{.key} = .value;
            }
            # redispatch
            self.ASSIGN-KEY($uri, $ns-map);
        }

        multi method ASSIGN-KEY(Str() $name, Str:D $val) is default {
            $!node.setAttribute($name, $val);
            self!store($name, $!node.getAttributeNode($name));
        }

        method DELETE-KEY(Str() $key) {
            self!unlink($key);
        }

        # DOM Support
        method setNamedItem($att) {
            $!node.addChild($att);
            self!tie-att($att);
        }

        method !tie-att(LibXML::Attr:D $att, Bool :$add = True) {
            my Str:D $name = $att.native.domName;
            my Str $uri;
            my ($prefix,$local-name) = $name.split(':', 2);

            if $local-name {
                %!ns{$prefix} = $!node.doc.native.SearchNs($!node.native, $prefix)
                    unless %!ns{$prefix}:exists;

                with %!ns{$prefix} -> $ns {
                    $uri = $ns.href;
                }
            }

            with $uri {
                self{$_} = %()
                    unless self{$_} ~~ AttrMapNs;

                $_!AttrMapNs::store($local-name, $att)
                    given %!store{$_};
            }
            else {
                self!store($name, $att);
            }

        }

        method removeNamedItem(Str:D $name) {
            self{$name}:delete;
        }
    }

    my AttrMap $atts .= new: :node(self);
    $atts;
}

method !set-attributes(%atts) {
    # clear out old attributes
    with $.native.properties -> domNode:D $node is copy {
        while $node.defined {
            my $next = $node.next;
            $node.Release
                if $node.type == XML_ATTRIBUTE_NODE;
            $node = $next;
        }
    }
    # set new attributes
    for %atts.pairs.sort -> $att, {
        if $att.value ~~ NameVal|Hash {
            my $uri = $att.key;
            self.setAttributeNS($uri, $_)
                for $att.value.pairs.sort;
        }
        else {
            self.setAttribute($att.key, $att.value);
        }
    }
}

# hashy attribute containers
method attributes is rw {
    Proxy.new(
        FETCH => sub ($) { self!get-attributes },
        STORE => sub ($, %atts) {
            self!set-attributes(%atts);
        }
    );
}

# attributes as an ordered list
method properties {
    iterate(LibXML::Attr, $.native.properties);
}

method appendWellBalancedChunk(Str:D $string) {
    require LibXML::DocumentFragment;
    my $frag = LibXML::DocumentFragment.new;
    $frag.parse: :balanced, :$string;
    self.appendChild( $frag );
}
