#| methods common to elements, documents and document fragments
unit role LibXML::_ParentNode;

use LibXML::Node;
use LibXML::Config;
use LibXML::Types :QName, :NameVal;
use LibXML::Utils :iterate-set;

method getElementsByTagName(Str:D $name) {
    iterate-set(LibXML::Node, $.raw.getElementsByTagName($name));
}
method getElementsByLocalName(Str:D $name) {
    iterate-set(LibXML::Node, $.raw.getElementsByLocalName($name));
}
method getElementsByTagNameNS(Str $uri, Str $name) {
    iterate-set(LibXML::Node, $.raw.getElementsByTagNameNS($uri, $name));
}
method getChildrenByLocalName(Str:D $name) {
    iterate-set(LibXML::Node, $.raw.getChildrenByLocalName($name));
}
method getChildrenByTagName(Str:D $name) {
    iterate-set(LibXML::Node, $.raw.getChildrenByTagName($name));
}
method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
    iterate-set(LibXML::Node, $.raw.getChildrenByTagNameNS($uri, $name));
}
method elements {
    iterate-set(LibXML::Node, $.raw.getChildrenByLocalName('*'));
}

#| adds a child element with tag $name and text content $value
multi method appendTextChild(QName:D $name, Str $value? --> LibXML::Node) {
    self.box: $.raw.appendTextChild($name, $value);
}

multi method appendTextChild(NameVal:D $_) {
    $.appendTextChild(.key, .value);
}

method ast(LibXML::Config :$config, Bool :$blank = $config.keep-blanks --> Pair) {
    self.ast-key => [self.childNodes(:$blank).map(*.ast: :$blank)];
}
