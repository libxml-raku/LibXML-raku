#| low level DOM. Works directly on Native XML Nodes
unit role LibXML::Native::DOM::Node;
my constant Node = LibXML::Native::DOM::Node;
use LibXML::Enums;
use NativeCall;

method doc { ... }
method type { ... }
method children { ... }
method last { ... }

method domAppendChild  { ... }
method domInsertBefore { ... }
method domInsertAfter  { ... }
method domName { ... }
method domGetNodeValue { ... }
method domSetNodeValue { ... }
method domRemoveChild  { ... }

method firstChild { self.children }
method lastChild { self.last }

method appendChild(Node $nNode) {
    if self.type == XML_DOCUMENT_NODE {
        my constant %Unsupported = %(
            (+XML_ELEMENT_NODE) => "Appending an element to a document node not supported yet!",
            (+XML_DOCUMENT_FRAG_NODE) => "Appending a document fragment node to a document node not supported yet!",
            (+XML_TEXT_NODE|+XML_CDATA_SECTION_NODE)
                => "Appending text node not supported on a document node yet!",
        );

        fail $_ with %Unsupported{$nNode.type};
    }
    my Node:D $rNode = self.domAppendChild($nNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $rNode;
}

method removeChild(Node $child) {
    self.domRemoveChild($child);
}

method insertBefore(Node $nNode, Node $oNode) {
    my Node:D $rNode = self.domInsertBefore($nNode, $oNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $nNode;
}

method insertAfter(Node $nNode, Node $oNode) {
    my Node:D $rNode = self.domInsertAfter($nNode, $oNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $nNode;
}

method nodeName {
    self.domName;
}

method nodeValue is rw {
    Proxy.new(
        FETCH => sub ($) { self.domGetNodeValue },
        STORE => sub ($, Str() $_) { self.domSetNodeValue($_) },
    );
}

method hasChildNodes returns Bool {
    ? (self.type != XML_ATTRIBUTE_NODE && self.children.defined)
}

sub addr($d) { +nativecast(Pointer, $_) with $d;  }

method isSameNode(Node $oNode) {
    addr(self) ~~ addr($oNode);
}

method baseURI is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetBase },
        STORE => sub ($, Str() $uri) { self.SetBase($uri) }
    );
}

