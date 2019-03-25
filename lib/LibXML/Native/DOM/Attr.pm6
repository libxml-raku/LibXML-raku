#| low level DOM. Works directly on Native XML Nodes
unit role LibXML::Native::DOM::Attr;
my constant Attr = LibXML::Native::DOM::Attr;
use LibXML::Enums;
use LibXML::Types :NCName, :QName;
use NativeCall;

method domAttrSerializeContent { ... }

method serializeContent {
    self.domAttrSerializeContent;
}
