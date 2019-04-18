unit class LibXML::Namespace;
use LibXML::Native;
use LibXML::Types :NCName;
use NativeCall;
has xmlNs $!struct handles <type prefix href Str>;

method box(xmlNs:D $struct!) {
    self.new: :$struct;
}

multi submethod TWEAK(xmlNs:D :$!struct!) {
    $!struct .= Copy;
    $!struct.add-reference;
}

multi submethod TWEAK(Str:D :$href!, NCName :$prefix, :node($node-obj)) {
    my domNode $node = .unbox with $node-obj;
    $!struct .= new: :$href, :$prefix, :$node;
    $!struct.add-reference;
}

method nodeType     { $!struct.type }
method localname    { $!struct.prefix }
method string-value { $!struct.href }

submethod DESTROY {
    with $!struct {
        .Free if .remove-reference;
    }
}
