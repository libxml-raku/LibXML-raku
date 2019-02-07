class LibXML::Node {
    use LibXML::Native;
    use LibXML::Enums;
    has LibXML::Node $.root;
    has _xmlNode $.node handles <Str string-value content hasChildNodes URI baseURI nodeName nodeValue>;
    method nodeType { $!node.type }
    method localname { $!node.name }
    method prefix { .prefix with $!node.ns }
    method namespaceURI { .href with $!node.ns }
    BEGIN {
        # wrap methods that return raw nodes
        # no arguments
        for <last parent next prev doc firstChild lastChild documentElement> {
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
            when XML_DOCUMENT_FRAG_NODE { require LibXML::DocumentFragment }
            default {
                warn "node content-type not yet handled: $_";
                LibXML::Node;
            }
        }
    }

    method dom-node(_xmlNode $node, :$root = $.root) { with $node { delegate($node).new: :$node, :$root} else { xmlNode }; }
    method set-node($!node) {};

    our sub iterate($obj, $cur, :$root = $obj.root) is rw is export(:iterate) {
        # follow a chain of .next links.
        my class Siblings does Iterable does Iterator {
            has $.cur;
            method iterator { self }
            method pull-one {
                my $this = $!cur;
                $_ = .next with $!cur;
                with $this -> $node {
                    $obj.dom-node: $node, :$root;
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :$cur );
    }

    # DOM methods
    method childNodes {
        iterate(self, $.node.children);
    }
}
