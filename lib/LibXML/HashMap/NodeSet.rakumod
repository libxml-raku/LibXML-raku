use LibXML::HashMap;
use LibXML::Node::Set;
class LibXML::HashMap::NodeSet
    is LibXML::HashMap[LibXML::Node::Set]
    is repr('CPointer') {
}
