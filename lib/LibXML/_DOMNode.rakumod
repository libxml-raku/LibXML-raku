unit role LibXML::_DOMNode;

use LibXML::Node :iterate-set;

method native {...}

method getElementsByTagName(Str:D $name) {
    iterate-set(LibXML::Node, $.native.getElementsByTagName($name));
}
method getElementsByLocalName(Str:D $name) {
    iterate-set(LibXML::Node, $.native.getElementsByLocalName($name));
}
method getElementsByTagNameNS(Str $uri, Str $name) {
    iterate-set(LibXML::Node, $.native.getElementsByTagNameNS($uri, $name));
}
method getChildrenByLocalName(Str:D $name) {
    iterate-set(LibXML::Node, $.native.getChildrenByLocalName($name));
}
method getChildrenByTagName(Str:D $name) {
    iterate-set(LibXML::Node, $.native.getChildrenByTagName($name));
}
method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
    iterate-set(LibXML::Node, $.native.getChildrenByTagNameNS($uri, $name));
}
method elements {
    iterate-set(LibXML::Node, $.native.getChildrenByLocalName('*'));
}
