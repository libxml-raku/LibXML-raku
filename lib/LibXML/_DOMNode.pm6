unit role LibXML::_DOMNode;

use LibXML::Node :iterate-set;

method native {...}

method getElementsByTagName(Str:D $name) {
    iterate-set(LibXML::_DOMNode, $.native.getElementsByTagName($name));
}
method getElementsByLocalName(Str:D $name) {
    iterate-set(LibXML::_DOMNode, $.native.getElementsByLocalName($name));
}
method getElementsByTagNameNS(Str $uri, Str $name) {
    iterate-set(LibXML::_DOMNode, $.native.getElementsByTagNameNS($uri, $name));
}
method getChildrenByLocalName(Str:D $name) {
    iterate-set(LibXML::_DOMNode, $.native.getChildrenByLocalName($name));
}
method getChildrenByTagName(Str:D $name) {
    iterate-set(LibXML::_DOMNode, $.native.getChildrenByTagName($name));
}
method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
    iterate-set(LibXML::_DOMNode, $.native.getChildrenByTagNameNS($uri, $name));
}

