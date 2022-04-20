use LibXML::HashMap;
use LibXML::Node::Set;

class LibXML::HashMap::NodeSet
    is repr('CPointer')
    is LibXML::HashMap[LibXML::Node::Set] {
}
