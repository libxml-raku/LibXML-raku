unit module LibXML::Utils;
use LibXML::Node::List;
use LibXML::Node::Set;
use LibXML::Raw;
use LibXML::Enums;
use LibXML::Config;

sub output-options(UInt :$options is copy = 0,
                   LibXML::Config :$config,
                   Bool :$format,
                   Bool :$skip-xml-declaration = $config.skip-xml-declaration,
                   Bool :$tag-expansion = $config.tag-expansion,
                   Bool :$html,
    # **DEPRECATED**
                   Bool :$skip-decl, Bool :$expand,
                   ) is export(:output-options) {

    warn ':skip-decl option is deprecated, please use :skip-xml-declaration'
        with $skip-decl;

    warn ':expand option is deprecated, please use :tag-expansion'
        with $expand;

    for $format => XML_SAVE_FORMAT, $skip-xml-declaration => XML_SAVE_NO_DECL, $tag-expansion =>  XML_SAVE_NO_EMPTY, $html => XML_SAVE_XHTML {
        $options +|= .value if .key;
    }

    $options;
}
