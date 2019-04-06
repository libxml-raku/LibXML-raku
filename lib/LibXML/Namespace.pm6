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
}

multi submethod TWEAK(Str:D :$href!, NCName :$prefix, :node($node-obj)) {
    my domNode $node = .unbox with $node-obj;
    $!struct .= new: :$href, :$prefix, :$node;
}

method nodeType  { $!struct.type }

submethod DESTROY {
    $!struct.Free;
}
