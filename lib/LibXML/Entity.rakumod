use LibXML::Dtd::Entity;

class LibXML::Entity is LibXML::Dtd::Entity is repr('CPointer') {
    method new(|) is DEPRECATED<LibXML::Dtd::Entity.new> { nextsame; }
}
