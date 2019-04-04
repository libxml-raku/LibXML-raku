unit class LibXML::Namespace;
use LibXML::Native;
use NativeCall;
has xmlNs $!struct handles <type prefix href Str>;
has Bool $!is-copy;

method box(xmlNs:D $struct!) {
    self.new: :$struct;
}

submethod TWEAK(xmlNs:D :$!struct!) {
    # LibXML refuses to copy 'xml' namespaces
    $!is-copy := $!struct.prefix !~~ 'xml';
    $!struct .= copy if $!is-copy;
}

method nodeType  { $!struct.type }

submethod DESTROY {
    $!struct.Free if $!is-copy;
}
