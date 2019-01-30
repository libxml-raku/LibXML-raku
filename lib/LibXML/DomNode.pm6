unit class LibXML::DomNode;
use LibXML::Native;

method node handles<firstChild> {
    nextsame;
}

method appendChild(xmlNode() $child-node) {
    $.node.appendChild($child-node);
}

BEGIN {
    # xmlNode() coercement
    $?CLASS.^add_method(
        'LibXML::Native::xmlNode', method (--> _xmlNode) {
            given self {
                when _xmlNode { self }
                when LibXML::DomNode { .node }
                default { die "don't know how to coerce {self.WHAT.^name} to an xmlNode" }
            }
        });
}

