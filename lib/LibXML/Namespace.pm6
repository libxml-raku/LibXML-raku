unit class LibXML::Namespace;
use LibXML::Native;
has $.doc;
has xmlNs $.ns handles <type prefix Str>;
method dom-node(xmlNs $ns, :$doc!) {
    with $ns {
        $?CLASS.new: :ns($_), :$doc;
    }
    else {
        $?CLASS;
    };
}
