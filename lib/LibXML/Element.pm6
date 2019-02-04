use LibXML::Node;

class LibXML::Element
    is LibXML::Node {

    use LibXML::Namespace;
    method attributes {
        LibXML::Node::iterate(self, $.node.properties);
    }

    method namespaces {
        LibXML::Node::iterate(LibXML::Namespace, $.node.nsDef, :$.root);
    }
}
