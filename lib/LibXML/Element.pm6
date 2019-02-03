use LibXML::Node :iterate;

unit class LibXML::Element
    is LibXML::Node;

method attributes {
    iterate(self, $.node.properties);
}

method namespaces {
    iterate(LibXML::Namespace, $.node.nsDef, :$.root);
}
