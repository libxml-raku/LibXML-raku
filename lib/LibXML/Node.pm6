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
        domCheck
        Str string-value content
        hasChildNodes hasAttributes
        lookupNamespacePrefix lookupNamespaceURI
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
            $?CLASS.^add_method($_, method (LibXML::Node:D $ret) { self.dom-node( $!node."$_"($ret.node), :$ret); });
        }
        for <replaceNode addSibling> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $new) { self.dom-node( $!node."$_"($new.node)); });
        }
        # single node argument unconstructed
        for <isSameNode> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $!node."$_"($n1.node) });
        }
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method(
                $_, method (LibXML::Node:D $ret, LibXML::Node $ref) {
                    self.dom-node($!node."$_"($ret.node, do with $ref {.node} else {domNode}), :$ret);
                });
        }
    }

    method replaceChild(LibXML::Node $new, $ret) {
        self.dom-node(
            $!node.replaceChild($new.node, $ret.node),
            :$ret
        );
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
            FETCH => sub ($) {
                given self.node.doc -> $node {
                    $!doc .= new: :$node
                        if ! ($!doc && !$!doc.node.isSameNode($node));
                }
                $!doc;
            },
            STORE => sub ($, LibXML::Node $doc) {
                with $doc {
                    unless ($!doc && $doc.isSameNode($!doc)) || $doc.isSameNode(self) {
                        $doc.node.domImportNode(self.node, my $_move = True, my $_reconcile = True);
                    }
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

    sub class-delegate(domNode $node) {
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

    sub node-delegate(UInt $_) {
        when XML_ELEMENT_NODE       { xmlNode }
        when XML_ATTRIBUTE_NODE     { xmlAttr }
        when XML_TEXT_NODE
           | XML_ENTITY_REF_NODE    { xmlTextNode }
        when XML_COMMENT_NODE       { xmlCommentNode }
        when XML_CDATA_SECTION_NODE { xmlCDataNode }
        when XML_PI_NODE            { xmlPINode }
        when XML_DOCUMENT_FRAG_NODE { xmlDocFrag }
        when XML_DOCUMENT_NODE      { xmlDoc }
        default {
            warn "node content-type not yet handled: $_";
            domNode;
        }
    }

    our sub cast-node(domNode:D $node is raw) {
        my $delegate := node-delegate($node.type);
        nativecast( $delegate, $node);
    }

    method dom-node(domNode $vanilla-node,
                    LibXML::Node :$doc is copy = $.doc, # reusable document object
                    LibXML::Node :$ret                  # reusable return container
                                 --> LibXML::Node) {
        with $vanilla-node {
            my $node := cast-node($_);
            given $node {
                when $ret.defined && $ret.node.isSameNode($_) {
                    $ret;
                }
                default {
                    # create a new object. reuse document object, if possible
                    with $node.doc -> $node-doc {
                        # can we reuse the document object?
                        with $doc {
                            $doc = LibXML::Node
                                unless .node.isSameNode($node-doc);
                        }
                    }
                    else {
                        # Not in a document
                        $doc = LibXML::Node;
                    }
                    with $ret {
                        # unable to reuse the container object for the returned node.
                        # unexpected, except for document fragments, which are discarded.
                        warn "hmm, returning unexpected node: {$node.Str}"
                            unless $ret.node.type == XML_DOCUMENT_FRAG_NODE;
                    }
                    class-delegate($_).new: :node($_), :$doc;
                }
            }
        } else {
            LibXML::Node;
        }
    }

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

    method ownerDocument { $!doc }
    my subset AttrNode of LibXML::Node where .nodeType == XML_ATTRIBUTE_NODE;
    multi method addChild(AttrNode $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method textContent { $.string-value }
    method unbindNode {
        $!node.Unlink;
        $!doc = LibXML::Node;
        self;
    }
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
        .Release with $!node.getAttributeNode($name);
        $!node.setAttribute($name, $value);
    }
    method setAttributeNode(AttrNode $att) {
        .Release with $!node.getAttributeNode($att.name);
        $!node.setAttributeNode($att.node);
    }
    multi method setAttributeNS(Str $uri, NameVal:D $_) {
        $!node.setAttributeNS($uri, .key, .value);
    }
    multi method setAttributeNS(Str $uri, QName $name, Str $value) {
        $!node.setAttributeNS($uri, $name, $value);
    }
    method getAttributeNode(Str $att-name --> LibXML::Node) {
        self.dom-node: $!node.getAttributeNode($att-name);
    }
    method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Node) {
        self.dom-node: $!node.getAttributeNodeNS($uri, $att-name);
    }
    method getAttributeNS(Str $uri, Str $att-name --> Str) {
        $!node.getAttributeNS($uri, $att-name);
    }
    method localNS {
        LibXML::Namespace.dom-node: $!node.localNS, :$!doc;
    }
    method getAttribute(Str $att-name --> Str) {
        $!node.getAttribute($att-name);
    }
    method removeAttribute(Str $attr-name) {
        .Release with $!node.getAttributeNode($attr-name);
    }
    method removeAttributeNS(Str $uri, Str $attr-name) {
        .Release with $!node.getAttributeNodeNS($uri, $attr-name);
    }
    method getNamespaces {
        $!node.getNamespaces.map: { LibXML::Namespace.dom-node($_, :$!doc) }
    }
    method removeChild(LibXML::Node:D $ret --> LibXML::Node) {
        with $!node.removeChild($ret.node) {
            $ret.doc = LibXML::Node;
            self.dom-node: $_, :$ret;
        }
        else {
            # not a child
            $ret.WHAT;
        }
    }
    method removeChildNodes(--> LibXML::Node) {
        self.dom-node: $!node.removeChildNodes;
    }
    method cloneNode(Bool() $deep) {
        my $node = $!node.cloneNode($deep);
        self.new: :$node;
    }
    method !get-attributes {

        role AttrMap[LibXML::Node $elem] does Associative {
            method ASSIGN-KEY(Str() $name, Str() $val) {
                if self{$name} ~~ Hash:D { # nested namespace elems
                    nextsame
                }
                else {
                    $elem.setAttribute($name, $val);
                    nextwith($name, $elem.getAttributeNode($name));
                }
            }

            method DELETE-KEY(Str() $key) {
                if self{$key} ~~ Hash:D { # nested namespace elems
                    self{$key}{$_}.DELETE-KEY
                        for self{$_}.keys;
                }
                else {
                    $elem.removeAttribute($key);
                }
                nextsame;
            }
        }

        role AttrMapNs[LibXML::Node $elem, Str $uri] does Associative {
            method ASSIGN-KEY(Str() $name, Str() $val) {
                $elem.setAttribute($name, $val);
                nextwith($name, $elem.getAttributeNodeNS($uri, $name));
            }

            method DELETE-KEY(Str() $key) {
                $elem.removeAttributeNS($uri, $key);
                nextsame;
            }
        }

        my xmlNs %ns;
        my %atts;
        my Bool %uris;
        with $!node.properties -> domNode:D $node is copy {
            my LibXML::Node $doc = self.doc;
            require LibXML::Attr;
            while $node.defined {
                my $uri;
                if $node.type == XML_ATTRIBUTE_NODE {
                    $node = nativecast(xmlAttr, $node);
                    my $att = LibXML::Attr.new: :$node, :$doc;
                    my Str:D $name = $node.domName;
                    my ($prefix,$local-name) = $name.split(':', 2);

                    if $local-name {
                        %ns{$prefix} = $doc.node.SearchNs($!node, $prefix)
                            unless %ns{$prefix}:exists;

                        with %ns{$prefix} -> $ns {
                            $uri = $ns.href;
                            %uris{$uri} = True;
                            %atts{$uri}{$local-name} = $att;
                        }
                    }

                    %atts{$name} = $att
                        unless $uri;
                }

                $node = $node.next;
            }
        }

        %atts{$_} does AttrMapNs[self,$_] for %uris.keys;
        %atts does AttrMap[self];
    }

    method !set-attributes(%atts) {
        # clear out old attributes
        with $!node.properties -> domNode:D $node is copy {
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
            if .remove-reference {
                # this node is no longer referenced
                given .root {
                    # release the entire tree, if possible
                    .Free unless .is-referenced;
                }
            }
            $_ = Nil;
        }
    }
}
