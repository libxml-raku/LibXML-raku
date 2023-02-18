#| methods common to elements, documents and document fragments
unit role LibXML::_ParentNode;

use LibXML::Node;
use LibXML::Config;
use LibXML::Enums;
use LibXML::Types :QName, :NameVal;

method iterate-set(|) {...}

method getElementsByTagName(Str:D $name) is raw {
    self.iterate-set(self.box-class(XML_ELEMENT_NODE), $.raw.getElementsByTagName($name));
}
method getElementsByLocalName(Str:D $name) {
    self.iterate-set(self.box-class(XML_ELEMENT_NODE), $.raw.getElementsByLocalName($name));
}
method getElementsByTagNameNS(Str $uri, Str $name) {
    self.iterate-set(self.box-class(XML_ELEMENT_NODE), $.raw.getElementsByTagNameNS($uri, $name));
}
method getChildrenByLocalName(Str:D $name) {
    self.iterate-set(LibXML::Node, $.raw.getChildrenByLocalName($name));
}
method getChildrenByTagName(Str:D $name) {
    self.iterate-set(LibXML::Node, $.raw.getChildrenByTagName($name));
}
method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
    self.iterate-set(LibXML::Node, $.raw.getChildrenByTagNameNS($uri, $name));
}
method elements {
    self.iterate-set(self.box-class(XML_ELEMENT_NODE), $.raw.getChildrenByLocalName('*'));
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
