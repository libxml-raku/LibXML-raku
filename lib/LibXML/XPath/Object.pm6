use v6;
unit class LibXML::XPath::Object;

use LibXML::Native;
use LibXML::Node :iterate, :XPathRange;

has xmlXPathObject $.native is required;

method select(Bool :$values) {
    given $!native.select {
        when xmlNodeSet { iterate(XPathRange, $_, :$values) }
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
