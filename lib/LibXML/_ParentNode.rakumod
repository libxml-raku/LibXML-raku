#| methods common to elements, documents and document fragments
unit role LibXML::_ParentNode;

use LibXML::Node :iterate-set;
use LibXML::Types :QName, :NameVal;
use LibXML::Config;
my constant config = LibXML::Config;

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

#| adds a child element with tag $name and text content $value
multi method appendTextChild(QName:D $name, Str $value? --> LibXML::Node) {
    self.box: $.native.appendTextChild($name, $value);
}

multi method appendTextChild(NameVal:D $_) {
    $.appendTextChild(.key, .value);
}

method ast(Bool :$blank = config.keep-blanks --> Pair) {
    self.ast-key => [self.childNodes(:$blank).map(*.ast: :$blank)];
}
