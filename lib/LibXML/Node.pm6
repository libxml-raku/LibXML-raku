class LibXML::Node {
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::Types :NCName, :QName;
    use NativeCall;

    my subset Nodeish where LibXML::Node|LibXML::Namespace;
    my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;

    has LibXML::Node $.doc;

    has domNode $.node handles <
        Str string-value content
        hasChildNodes hasAttributes
        URI baseURI nodeName nodeValue
    >;

    BEGIN {
        # wrap methods that return raw nodes
        # simple navigation; no arguments
        for <
             firstChild
             last lastChild
             next nextSibling nextNonBlankSibling
             parent parentNode
             prev previousSibling previousNonBlankSibling
        > {
            $?CLASS.^add_method($_, method { self.dom-node: $!node."$_"() });
        }
        # single node argument constructor
        for <appendChild> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { self.dom-node: $!node."$_"($n1.node) });
        }
        # single node argument
        for <isSameNode> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $!node."$_"($n1.node) });
        }
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1, LibXML::Node:D $n2) { self.dom-node: $!node."$_"($n1.node, $n2.node) });
        }
    }

    method node is rw {
        Proxy.new(
            FETCH => sub ($) { $!node },
            STORE => sub ($, domNode $new-node) {
                .remove-reference with $!node;
                .add-reference with $new-node;
                $!node = $new-node;
            },
        );
    }

    submethod TWEAK {
        .add-reference with $!node;
    }

    method doc is rw {
        Proxy.new(
            FETCH => sub ($) { $!doc },
            STORE => sub ($, LibXML::Node:D $doc) {
                with $!doc {
                    die "can't change owner document for a node"
                    unless $doc === $_;
                }
                $!doc = $doc;
            },
        );
    }

    method nodeType { $!node.type }
    method localname { $!node.name }
    method prefix { .prefix with $!node.ns }
    method namespaceURI { .href with $!node.ns }
    method line-number { $!node.GetLineNo }

    sub delegate(domNode $node) {
        given +$node.type {
            when XML_ELEMENT_NODE       { require LibXML::Element }
            when XML_ATTRIBUTE_NODE     { require LibXML::Attr }
            when XML_TEXT_NODE
               | XML_ENTITY_REF_NODE    { require LibXML::Text }
            when XML_COMMENT_NODE       { require LibXML::Comment }
            when XML_CDATA_SECTION_NODE { require LibXML::CDATASection }
            when XML_PI_NODE            { require LibXML::PI }
            when XML_DOCUMENT_FRAG_NODE { require LibXML::DocumentFragment }
            default {
                warn "node content-type not yet handled: $_";
                LibXML::Node;
            }
        }
    }

    method dom-node(domNode $node, :$doc = $.doc) { with $node { delegate($_).new: :node($_), :$doc} else { domNode }; }

    our proto sub iterate(Nodeish, $struct, :doc($)) {*}

    multi sub iterate(Nodeish $obj, $start, :$doc = $obj.doc) {
        # follow a chain of .next links.
        my class NodeList does Iterable does Iterator {
            has $.cur;
            method iterator { self }
            method pull-one {
                my $this = $!cur;
                $_ = .next with $!cur;
                with $this -> $node {
                    $obj.dom-node: $node, :$doc
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :cur($start) );
    }

    multi sub iterate(LibXML::Node $obj, xmlNodeSet $set, :$doc = $obj.doc) {
        # follow a chain of .next links.
        my class Node does Iterable does Iterator {
            has xmlNodeSet $.set;
            has UInt $!idx = 0;
            submethod DESTROY {
                # xmlNodeSet is managed by us
                with $!set { 
                  ##  xmlFree( nativecast(Pointer, $_) ); # segfaulting
                    $_ = Nil;
                }
            }
            method iterator { self }
            method pull-one {
                if $!set.defined && $!idx < $!set.nodeNr {
                    my domNode:D $node := nativecast(domNode, $!set.nodeTab[$!idx++]);
                        $obj.dom-node: $node
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :$set );
    }

    # DOM methods
    method !unlink(domNode $node) {
        $node.Unlink;
        $node.Free
           unless $node.is-referenced;
    }
    method ownerDocument { $!doc }
    my subset AttrNode of LibXML::Node where .nodeType == XML_ATTRIBUTE_NODE;
    multi method addChild(AttrNode $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method textContent { $.string-value }
    method childNodes {
        iterate(self, $!node.children);
    }
    method getElementsByTagName(Str:D $name) {
        iterate(self, $!node.getElementsByTagName($name));
    }
    method getElementsByLocalName(Str:D $name) {
        iterate(self, $!node.getElementsByLocalName($name));
    }
    method getElementsByTagNameNS(Str $uri, Str $name) {
        iterate(self, $!node.getElementsByTagNameNS($uri, $name));
    }
    method getChildrenByLocalName(Str:D $name) {
        iterate(self, $!node.getChildrenByLocalName($name));
    }
    method getChildrenByTagName(Str:D $name) {
        iterate(self, $!node.getChildrenByTagName($name));
    }
    method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
        iterate(self, $!node.getChildrenByTagNameNS($uri, $name));
    }
    method setAttribute(QName $name, Str $value) {
        self!unlink($_) with $!node.getAttributeNode($name);
        $!node.setAttribute($name, $value);
    }
    method setAttributeNode(AttrNode $att) {
        self!unlink($_) with $!node.getAttributeNode($att.name);
        $!node.setAttributeNode($att.node);
    }
    multi method setAttributeNS(Str $uri, NameVal:D $_) {
        $!node.setAttributeNS($uri, .key, .value);
    }
    multi method setAttributeNS(Str $uri, QName $name, Str $value) {
        $!node.setAttributeNS($uri, $name, $value);
    }
    method getAttributeNode(Str $att-name) {
        self.dom-node: $!node.getAttributeNode($att-name);
    }
    method getAttribute(Str $att-name) {
        $!node.getAttribute($att-name);
    }
    method removeAttribute(Str $attr-name) {
        self!unlink($_) with $!node.getAttributeNode($attr-name);
    }
    method removeChild(LibXML::Node:D $kid) {
        with $!node.removeChild($kid.node) {
            .Free unless .is-referenced;
            $_;
        }
    }
    method cloneNode(Bool() $recursive) {
        self.dom-node: $!node.cloneNode($recursive);
    }

    method !get-attributes {

        role AttrMap[LibXML::Node $elem] does Associative {
            method ASSIGN-KEY(Str() $name, Str() $val) {
                $elem.setAttribute($name, $val);
                nextwith($name, $elem.getAttributeNode($name));
            }

            method DELETE-KEY(Str() $key) {
                $elem.removeAttribute($key);
                nextsame;
            }
        }

        my xmlNs %ns;
        my %atts;
        with $!node.properties -> domNode:D $node is copy {
            my LibXML::Node $doc = self.doc;
            require LibXML::Attr;
            while $node.defined {
                my $has-namespace = False;
                if $node.type == XML_ATTRIBUTE_NODE {
                    $node = nativecast(xmlAttr, $node);
                    my $att = LibXML::Attr.new: :$node, :$doc;
                    my Str:D $name = $node.domName;
                    my ($prefix,$local-name) = $name.split(':', 2);

                    if $local-name {
                        %ns{$prefix} = $doc.node.SearchNs($!node, $prefix)
                            unless %ns{$prefix}:exists;

                        with %ns{$prefix} -> $ns {
                            $has-namespace = True;
                            %atts{$ns.href}{$local-name} = $att;
                        }
                    }

                    %atts{$name} = $att
                        unless $has-namespace;
                }

                $node = $node.next;
            }
        }
        %atts does AttrMap[self];
    }

    method !set-attributes(%atts) {
        # clear out old attributes
        with $!node.properties -> domNode:D $node is copy {
            my LibXML::Node $doc = self.doc;
            while $node.defined {
                my $next = $node.next;
                if $node.type == XML_ATTRIBUTE_NODE {
                    $node.Unlink;
                    $node.Free unless $node.is-referenced;
                }
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
        iterate(self, $.node.properties);
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
        with $!node {
            if $!node.remove-reference {
                # this node is no longer referenced
                given $!node.root {
                    # release the entire tree, if possible
                    .Free unless .is-referenced;
                }
            }
            $!node = Nil;
        }
    }
}
