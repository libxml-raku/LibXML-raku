#| low level DOM. Works directly on Native XML Nodes
unit role LibXML::Native::DOM::Node;
my constant DomNode = LibXML::Native::DOM::Node;
use LibXML::Enums;

method doc { ... }
method type { ... }
method children { ... }
method domAppendChild { ... }
method domInsertBefore { ... }

method firstChild { self.children }
method appendChild(DomNode $nNode) {
    if self.type == XML_DOCUMENT_NODE {
        my constant %Unsupported = %(
            (+XML_ELEMENT_NODE) => "Appending an element to a document node not supported yet!",
            (+XML_DOCUMENT_FRAG_NODE) => "Appending a document fragment node to a document node not supported yet!",
            (+XML_TEXT_NODE|+XML_CDATA_SECTION_NODE)
                => "Appending text node not supported on a document node yet!",
        );

        fail $_ with %Unsupported{$nNode.type};
    }
    my DomNode:D $rNode = self.domAppendChild($nNode);
    self.doc.xml6_doc_set_int_subset($nNode)
        if $rNode.type == XML_DTD_NODE;
    $rNode;
}
method insertBefore(DomNode $nNode, DomNode $oNode) {
    my DomNode:D $rNode = self.domInsertBefore($nNode, $oNode);
    self.doc.xml6_doc_set_int_subset($nNode)
        if $rNode.type == XML_DTD_NODE;
    $nNode;
}
