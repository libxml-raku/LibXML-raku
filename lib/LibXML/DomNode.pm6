unit class LibXML::DomNode;
use LibXML::Native;

method node handles<firstChild lastChild hasChildNodes> {
    nextsame;
}

method appendChild(xmlNode() $new-child) {
    $.node.appendChild($new-child);
}

method insertBefore(xmlNode() $new-child, xmlNode() $ref-child) {
    $.node.insertBefore($new-child, $ref-child);
}

method insertAfter(xmlNode() $new-child, xmlNode() $ref-child) {
    $.node.insertAfter($new-child, $ref-child);
}

method isSameNode(xmlNode() $other-node) {
    $.node.isSameNode($other-node);
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

