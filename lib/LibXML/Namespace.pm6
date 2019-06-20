unit class LibXML::Namespace;
use LibXML::Native;
use LibXML::Types :NCName;
use NativeCall;
has xmlNs $!native handles <type prefix href Str>;

method box(xmlNs $ns!) {
    do with $ns {
        self.new: :native($_);
    } // self.WHAT;
}

multi submethod TWEAK(xmlNs:D :$!native!) {
    $!native .= Copy;
    $!native.add-reference;
}

multi submethod TWEAK(Str:D :$href!, NCName :$prefix, :node($node-obj)) {
    my domNode $node = .native with $node-obj;
    $!native .= new: :$href, :$prefix, :$node;
    $!native.add-reference;
}

method nodeType     { $!native.type }
method localname    { $!native.prefix }
method string-value { $!native.href }

submethod DESTROY {
    with $!native {
        .Free if .remove-reference;
    }
}
