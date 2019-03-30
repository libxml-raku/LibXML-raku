unit class LibXML::Namespace;
use LibXML::Native;
use NativeCall;
has xmlNs $struct handles <type prefix href Str>;
method unbox { $!struct }
method box(xmlNs:D $struct!) {
    self.new: :$struct;
}

submethod TWEAK(xmlNs:D :struct($ns)!) {
    # LibXML refuses to copy 'xml' namespaces
    $!struct := $ns.prefix ~~ 'xml' ?? $ns !! $ns.copy;
}

method nodeType  { $.unbox.type }

submethod DESTROY {
    with $!struct {
        .Free unless .prefix ~~ 'xml';
    }
}
