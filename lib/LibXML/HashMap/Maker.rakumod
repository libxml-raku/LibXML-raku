class LibXML::HashMap::Maker {
    use LibXML::HashMap;
    use LibXML::Node::Set;
    method CALL-ME(\type) { LibXML::HashMap[type] };
}
