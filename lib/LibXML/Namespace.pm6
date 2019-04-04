unit class LibXML::Namespace;
use LibXML::Native;
use NativeCall;
has xmlNs $!struct handles <type prefix href Str>;

method box(xmlNs:D $struct!) {
    self.new: :$struct;
}

submethod TWEAK(xmlNs:D :$!struct!) {
    $!struct .= Copy;
}

method nodeType  { $!struct.type }

submethod DESTROY {
    $!struct.Free;
}
