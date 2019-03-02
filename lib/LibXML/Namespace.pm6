unit class LibXML::Namespace;
use LibXML::Native;
has xmlNs $.ns handles <type prefix Str>;
method dom-node(xmlNs $ns, :$doc!) {
    with $ns {
        $?CLASS.new: :ns($_);
    }
    else {
        $?CLASS;
    };
}

submethod TWEAK {
    $!ns .= copy;
}

submethod DESTROY {
    with $!ns {
        .Free;
        $_ = Nil;
    }
}
