class LibXML::Node {
    use LibXML::Native;
    use LibXML::Enums;
    has LibXML::Node $.doc;

    has _xmlNode $.node handles <Str string-value content hasChildNodes URI baseURI nodeName nodeValue>;

    method node is rw {
        Proxy.new(
            FETCH => sub ($) { $!node },
            STORE => sub ($, _xmlNode $new-node) {
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
    BEGIN {
        # wrap methods that return raw nodes
        # no arguments
        for <last parent next prev firstChild lastChild> {
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

    method line-number { $!node.GetLineNo }

    sub delegate(_xmlNode $node) {
        given $node.type {
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

    method dom-node(_xmlNode $node, :$doc = $.doc) { with $node { delegate($node).new: :$node, :$doc} else { Nil }; }

    our sub iterate($obj, $cur, :$doc = $obj.doc) is rw is export(:iterate) {
        # follow a chain of .next links.
        my class Siblings does Iterable does Iterator {
            has $.cur;
            method iterator { self }
            method pull-one {
                my $this = $!cur;
                $_ = .next with $!cur;
                with $this -> $node {
                    $obj.dom-node: $node, :$doc;
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :$cur );
    }

    # DOM methods
    method !unlink(_xmlNode $node) {
        $node.Unlink;
        $node.Free
           unless $node.is-referenced;
    }
    my subset AttrNode of LibXML::Node where .nodeType == XML_ATTRIBUTE_NODE;
    multi method addChild(AttrNode $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method childNodes {
        iterate(self, $!node.children);
    }
    method setAttributeNode(AttrNode $att) {
        self!unlink($_) with $!node.getAttributeNode($att.name);
        $!node.setAttributeNode($att.node);
    }
    method getAttributeNode(Str $att-name) {
        self.dom-node: $!node.getAttributeNode($att-name);
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
