use v6;
unit class LibXML::XPath::Object;

use LibXML::Native;
use LibXML::Node :iterate-set, :NodeSetElem;
use LibXML::Node::Set;

has xmlXPathObject $.native is required;

my subset XPathRange is export(:XPathRange) where Bool|Numeric|Str|LibXML::Node::Set;

method select(Bool :$values --> XPathRange) {
    given $!native.select {
        when xmlNodeSet { iterate-set(NodeSetElem, $_, :$values) }
        default { $_ }
    }
}

submethod TWEAK { $!native.add-reference }

submethod DESTROY {
    with $!native {
        .Free
            if .remove-reference;
    }
}
