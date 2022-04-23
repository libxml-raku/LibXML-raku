unit module LibXML::Utils;
use LibXML::Node::List;
use LibXML::Node::Set;
use LibXML::Raw;
use LibXML::Enums;
use LibXML::Config;

sub iterate-list($parent, $of, Bool :$blank = True) is export(:iterate-list) {
    # follow a chain of .next links.
    LibXML::Node::List.new: :$of, :$blank, :$parent;
}

sub iterate-set($of, xmlNodeSet $raw, Bool :$deref) is export(:iterate-set) {
    # iterate through a set of nodes
    LibXML::Node::Set.new( :$raw, :$of, :$deref );
}

sub output-options(UInt :$options is copy = 0,
                   Bool :$format,
                   Bool :$skip-xml-declaration = LibXML::Config.skip-xml-declaration,
                   Bool :$tag-expansion = LibXML::Config.tag-expansion,
    # **DEPRECATED**
                   Bool :$skip-decl, Bool :$expand,
                   ) is export(:output-options) {

    warn ':skip-decl option is deprecated, please use :skip-xml-declaration'
    with $skip-decl;
    warn ':expand option is deprecated, please use :tag-expansion'
    with $expand;
    for $format => XML_SAVE_FORMAT, $skip-xml-declaration => XML_SAVE_NO_DECL, $tag-expansion =>  XML_SAVE_NO_EMPTY {
        $options +|= .value if .key;
    }

    $options;
}
