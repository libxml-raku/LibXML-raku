class LibXML::Node {
    use LibXML::Native;
    use LibXML::Native::DOM::Node;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::Types :NCName, :QName;
    use NativeCall;

    my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;
    enum <SkipBlanks KeepBlanks>;

    has LibXML::Node $.doc;

    has domNode $!struct handles <
        domCheck
        Str string-value content
        getAttribute getAttributeNS
        hasChildNodes hasAttributes hasAttribute hasAttributeNS
        lookupNamespacePrefix lookupNamespaceURI
        removeAttribute removeAttributeNS
        URI baseURI nodeName nodeValue
    >;

    BEGIN {
        # wrap methods that return raw nodes
        # simple navigation; no arguments
        for <
             firstChild firstNonBlankChild
             last lastChild
             next nextSibling nextNonBlankSibling
             parent parentNode
             prev previousSibling previousNonBlankSibling
        > {
            $?CLASS.^add_method($_, method { self.box: $.unbox."$_"() });
        }
        # single node argument constructor
        for <appendChild> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $box) { self.box( $.unbox."$_"($box.unbox), :$box); });
        }
        for <replaceNode addSibling> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $new) { self.box( $.unbox."$_"($new.unbox)); });
        }
        # single node argument unconstructed
        for <isSameNode> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $.unbox."$_"($n1.unbox) });
        }
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method(
                $_, method (LibXML::Node:D $box, LibXML::Node $ref) {
                    self.box($.unbox."$_"($box.unbox, do with $ref {.unbox} else {domNode}), :$box);
                });
        }
    }

    method replaceChild(LibXML::Node $new, $box) {
        self.box(
            $.unbox.replaceChild($new.unbox, $box.unbox),
            :$box
        );
    }

    method struct is rw {
        Proxy.new(
            FETCH => sub ($) { $!struct },
            STORE => sub ($, domNode:D $new-struct) {
                die "mismatch between DOM node of type {$new-struct.type} ({box-class($new-struct).perl}) and container object of class {self.WHAT.perl}"
                    unless self ~~ box-class($new-struct);
                .remove-reference with $!struct;
                .add-reference with $new-struct;
                $!struct = cast-struct($new-struct);
            },
        );
    }

    submethod TWEAK(domNode :$struct) {
        self.struct = $_
            with $struct;
    }

    method doc is rw {
        Proxy.new(
            FETCH => sub ($) {
                with self.unbox.doc -> $struct {
                    $!doc .= new: :$struct
                        if ! ($!doc && !$!doc.unbox.isSameNode($struct));
                }
                else {
                    $!doc = Nil;
                }
                $!doc;
            },
            STORE => sub ($, LibXML::Node $doc) {
                with $doc {
                    unless ($!doc && $doc.isSameNode($!doc)) || $doc.isSameNode(self) {
                        $doc.adoptNode(self);
                    }
                }
                $!doc = $doc;
            },
        );
    }

    method nodeType  { $.unbox.type }
    method tagName   { $.nodeName }
    method name      { $.nodeName }
    method localname { $.unbox.name }
    method line-number { $.unbox.GetLineNo }

    sub box-class(domNode $node) {
        given +$node.type {
            when XML_ELEMENT_NODE       { require LibXML::Element }
            when XML_ATTRIBUTE_NODE     { require LibXML::Attr }
            when XML_TEXT_NODE          { require LibXML::Text }
            when XML_ENTITY_REF_NODE    { require LibXML::EntityRef }
            when XML_COMMENT_NODE       { require LibXML::Comment }
            when XML_CDATA_SECTION_NODE { require LibXML::CDATASection }
            when XML_PI_NODE            { require LibXML::PI }
            when XML_DOCUMENT_FRAG_NODE { require LibXML::DocumentFragment }
            when XML_DOCUMENT_NODE
               | XML_HTML_DOCUMENT_NODE { require LibXML::Document }

            default {
                warn "node content-type not yet handled: $_";
                LibXML::Node;
            }
        }
    }

    sub delegate-struct(UInt $_) {
        when XML_ELEMENT_NODE       { xmlNode }
        when XML_ATTRIBUTE_NODE     { xmlAttr }
        when XML_TEXT_NODE          { xmlTextNode }
        when XML_ENTITY_REF_NODE    { xmlEntityRefNode }
        when XML_COMMENT_NODE       { xmlCommentNode }
        when XML_CDATA_SECTION_NODE { xmlCDataNode }
        when XML_PI_NODE            { xmlPINode }
        when XML_DOCUMENT_FRAG_NODE { xmlDocFrag }
        when XML_DOCUMENT_NODE
           | XML_HTML_DOCUMENT_NODE { xmlDoc }
        default {
            warn "node content-type not yet handled: $_";
            domNode;
        }
    }

    our sub cast-struct(domNode:D $struct is raw) {
        my $delegate := delegate-struct($struct.type);
        nativecast( $delegate, $struct);
    }

    method unbox {$!struct}

    method box(LibXML::Native::DOM::Node $struct,
                    LibXML::Node :$doc is copy = $.doc, # reusable document object
                    LibXML::Node :$box                  # reusable return container
                                 --> LibXML::Node) {
        with $struct {
            if $box.defined && $box.unbox.isSameNode($_) {
                $box;
            }
            else {
                # create a new box object. reuse document object, if possible
                with $box {
                    # unable to reuse the container object for the returned node.
                    # unexpected, except for document fragments, which are discarded.
                    die "returned unexpected node: {$.Str}"
                        unless $box.unbox.type == XML_DOCUMENT_FRAG_NODE;
                }
                box-class($_).new: :struct($_), :$doc;
            }
        }
        else {
            LibXML::Node;
        }
    }

    our proto sub iterate(LibXML::Node, $struct, :doc($), :keep-blanks($)) {*}

    multi sub iterate(LibXML::Node $obj, $start, :$doc = $obj.doc, Bool :$keep-blanks = True) {
        # follow a chain of .next links.
        my class NodeList does Iterable does Iterator {
            has $.cur;
            method iterator { self }
            method pull-one {
                my $this = $!cur;
                $_ = .next-node($keep-blanks) with $!cur;
                with $this -> $node {
                    $obj.box: $node, :$doc
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :cur($start) );
    }

    multi sub iterate(LibXML::Node $obj, xmlNodeSet $set, :$doc = $obj.doc) {
        # iterate through a set of nodes
        my class Node does Iterable does Iterator {
            has xmlNodeSet $.set;
            has UInt $!idx = 0;
            submethod DESTROY {
                # xmlNodeSet is managed by us
                .Free with $!set;
            }
            method iterator { self }
            method pull-one {
                if $!set.defined && $!idx < $!set.nodeNr {
                    my domNode:D $node := nativecast(domNode, $!set.nodeTab[$!idx++]);
                        $obj.box: $node
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :$set );
    }

    method ownerDocument is rw { $.doc }
    method setOwnerDocument(LibXML::Node:D $_) { self.doc = $_ }
    my subset AttrNode of LibXML::Node where { !.defined || .nodeType == XML_ATTRIBUTE_NODE };
    multi method addChild(AttrNode:D $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method textContent { $.string-value }
    method unbindNode {
        $.unbox.Unlink;
        $!doc = LibXML::Node;
        self;
    }
    method childNodes {
        iterate(self, $.unbox.first-child(KeepBlanks));
    }
    method nonBlankChildNodes {
        iterate(self, $.unbox.first-child(SkipBlanks), :!keep-blanks);
    }
    method getElementsByTagName(Str:D $name) {
        iterate(self, $.unbox.getElementsByTagName($name));
    }
    method getElementsByLocalName(Str:D $name) {
        iterate(self, $.unbox.getElementsByLocalName($name));
    }
    method getElementsByTagNameNS(Str $uri, Str $name) {
        iterate(self, $.unbox.getElementsByTagNameNS($uri, $name));
    }
    method getChildrenByLocalName(Str:D $name) {
        iterate(self, $.unbox.getChildrenByLocalName($name));
    }
    method getChildrenByTagName(Str:D $name) {
        iterate(self, $.unbox.getChildrenByTagName($name));
    }
    method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
        iterate(self, $.unbox.getChildrenByTagNameNS($uri, $name));
    }
    method setAttribute(QName $name, Str:D $value) {
        $.unbox.setAttribute($name, $value);
    }
    method setAttributeNode(AttrNode:D $box) {
        self.box: $.unbox.setAttributeNode($box.unbox), :$box;
    }
    method setAttributeNodeNS(AttrNode:D $box) {
        self.box: $.unbox.setAttributeNodeNS($box.unbox), :$box;
    }
    multi method setAttributeNS(Str $uri, NameVal:D $_) {
        $.unbox.setAttributeNS($uri, .key, .value);
    }
    multi method setAttributeNS(Str $uri, QName $name, Str $value) {
        self.box: $.unbox.setAttributeNS($uri, $name, $value);
    }
    method getAttributeNode(Str $att-name --> LibXML::Node) {
        self.box: $.unbox.getAttributeNode($att-name);
    }
    method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Node) {
        self.box: $.unbox.getAttributeNodeNS($uri, $att-name);
    }
    method localNS {
        LibXML::Namespace.box: $.unbox.localNS, :$.doc;
    }

    method getNamespaces {
        $.unbox.getNamespaces.map: { LibXML::Namespace.box($_, :$.doc) }
    }
    method removeChild(LibXML::Node:D $box --> LibXML::Node) {
        with $.unbox.removeChild($box.unbox) {
            $box.doc = LibXML::Node;
            self.box: $_, :$box;
        }
        else {
            # not a child
            $box.WHAT;
        }
    }
    method removeAttributeNode(AttrNode $box) {
        self.box: $.unbox.removeAttributeNode($box.unbox), :$box;
    }
    method removeChildNodes(--> LibXML::Node) {
        self.box: $.unbox.removeChildNodes;
    }
    method cloneNode(Bool() $deep) {
        my $struct = $.unbox.cloneNode($deep);
        self.new: :$struct, :$.doc;
    }
    method !get-attributes {

        class AttrMap {...}
        class AttrMapNs does Associative {
            trusts AttrMap;
            has LibXML::Node $.node;
            has Str:D $.uri is required;
            has AttrNode:D %!store handles <EXISTS-KEY Numeric keys pairs kv elems>;

            method !unlink(Str:D $key) {
                $!node.removeChild($_)
                    with %!store{$key}:delete;
            }
            method !store(Str:D $name, AttrNode:D $att) {
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
            my subset AttrMapNode where AttrNode:D|AttrMapNs:D;
            has AttrMapNode %!store handles <EXISTS-KEY Numeric keys pairs kv elems>;

            submethod TWEAK() {
                with $!node.unbox.properties -> domNode $prop is copy {
                    my LibXML::Node $doc = $!node.doc;
                    require LibXML::Attr;
                    while $prop.defined {
                        my $uri;
                        if $prop.type == XML_ATTRIBUTE_NODE {
                            my xmlAttr $struct := nativecast(xmlAttr, $prop);
                            my $att := LibXML::Attr.new: :$struct, :$doc;
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

            method !tie-att(AttrNode:D $att, Bool :$add = True) {
                my Str:D $name = $att.unbox.domName;
                my Str $uri;
                my ($prefix,$local-name) = $name.split(':', 2);

                if $local-name {
                    %!ns{$prefix} = $!node.doc.unbox.SearchNs($!node.unbox, $prefix)
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
        with $.unbox.properties -> domNode:D $node is copy {
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

    method attributes is rw {
        Proxy.new(
            FETCH => sub ($) { self!get-attributes },
            STORE => sub ($, %atts) {
                self!set-attributes(%atts);
            }
        );
    }

    method properties {
        iterate(self, $.unbox.properties);
    }

    multi method write(IO::Handle :$io!, Bool :$format = False) {
        $io.write: self.Blob(:$format);
    }

    multi method write(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :w);
        $.write(:$io, |c);
        $io;
    }

    multi method write(IO() :file($io)!, |c) {
        $.write(:$io, |c).close;
    }

    submethod DESTROY {
        with $!struct {
            if .remove-reference {
                # this node is no longer referenced
                given .root {
                    # release the entire tree, if possible
                    .Free unless .is-referenced;
                }
            }
        }
    }
}
