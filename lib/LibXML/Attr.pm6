use LibXML::Node;

unit class LibXML::Attr
    is LibXML::Node;

method node handles <atype def defaultValue tree prefix elem> {
    nextsame;
}

method nexth returns LibXML::Attr {
    self.proxy-node: $.node.nexth, :class(LibXML::Attr);
}
