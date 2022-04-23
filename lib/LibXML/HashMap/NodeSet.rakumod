class LibXML::HashMap::NodeSet is repr('CPointer') {
    use LibXML::HashMap;
    use LibXML::Node::Set;
    
    also is LibXML::HashMap[LibXML::Node::Set];
}
