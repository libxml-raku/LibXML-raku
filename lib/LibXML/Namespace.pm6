unit class LibXML::Namespace;
use LibXML::Native;
has xmlNs $.struct handles <type prefix Str>;
method unbox { $!struct }
method box(xmlNs:D $struct!, :$doc!) {
    $?CLASS.new: :$struct;
}

submethod TWEAK {
    $!struct .= copy;
}

submethod DESTROY {
    .Free with $!struct;
}
