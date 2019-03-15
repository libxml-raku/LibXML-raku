unit class LibXML::Namespace;
use LibXML::Native;
has xmlNs $.struct handles <type prefix Str>;
method dom-node(xmlNs:D $struct!, :$doc!) {
    $?CLASS.new: :$struct;
}

submethod TWEAK {
    $!struct .= copy;
}

submethod DESTROY {
    with $!struct {
        .Free;
        $_ = Nil;
    }
}
