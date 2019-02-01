unit class LibXML::Node;
use LibXML::Native;
has LibXML::Node $.root;
has _xmlNode $.node handles <Str type content hasChildNodes namespaces>;

BEGIN {
    # wrap methods that return raw nodes
    # no arguments
    for <last parent next prev doc firstChild lastChild documentElement> {
        $?CLASS.^add_method($_, method { self.proxy-node: $!node."$_"() });
    }
    # single node argument constructor
    for <appendChild> {
        $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { self.proxy-node: $!node."$_"($n1.node) });
    }
    # single node argument
    for <isSameNode> {
        $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $!node."$_"($n1.node) });
    }
    # two node arguments
    for <insertBefore insertAfter> {
        $?CLASS.^add_method($_, method (LibXML::Node:D $n1, LibXML::Node:D $n2) { self.proxy-node: $!node."$_"($n1.node, $n2.node) });
    }
}

method line-number { $!node.GetLineNo }

method proxy-node(_xmlNode $node) { with $node { $?CLASS.new: :$node, :$.root} else { $?CLASS }; }
method set-node($!node) {};

sub iterate($obj, _xmlNode $cur) is rw {
    # follow a chain of .next links.
    my class Siblings does Iterable does Iterator {
        has _xmlNode $.cur;
        method iterator { self }
        method pull-one {
            my _xmlNode $this = $!cur;
            $_ = .next with $!cur;
            with $this -> $node {
                $obj.proxy-node: $node
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

method attributes {
    iterate(self, $.node.properties);
}
