unit class LibXML::Writer;

use LibXML::ErrorHandling;
use LibXML::_Configurable;

also does LibXML::_Configurable;
also does LibXML::ErrorHandling;

use LibXML::Raw;
use LibXML::Raw::TextWriter;
use LibXML::Types :QName, :NCName;
use LibXML::Document;
use LibXML::Node;
use Method::Also;
use NativeCall;

has xmlTextWriter $.raw is built;

has LibXML::Document $.doc is built;
has LibXML::Node     $.node is built;

#| Ensure libxml2 has been compiled with the tex-writer enabled
method have-writer {
    ? xml6_config_have_libxml_writer();
}

multi method TWEAK(LibXML::Node :$!node!, LibXML::Document:D :$!doc = $!node.doc) {
    my xmlDoc  $doc  = $!doc.raw;
    my xmlNode $node = .raw with $!node;
    $!raw = xmlTextWriter.new: :$doc, :$node;
}

multi method TWEAK(LibXML::Document:D :$!doc!) {
    my xmlDoc  $doc  = $!doc.raw;
    my xmlNode $node = .raw with $!node;
    $!raw = xmlTextWriter.new: :$doc, :$node;
}

method recover is also<suppress-errors suppress-warnings> { False }

method !write(Str:D $op, |c) is hidden-from-backtrace {
    my Int $rv := $!raw."$op"(|c);
    self.flush-errors;
    fail X::LibXML::OpFail.new(:what<Write>, :$op)
        if $rv < 0;
    $rv;
}

multi trait_mod:<is>(
    Method $m, # where {.yada && .count <= 1},
    :$writer-raw!) {
    my $name := $m.name;
    $m.wrap(method (|c) is hidden-from-backtrace { self!write($name, |c) })
}

## traits not working
## method startElement(QName $name) is writer-raw {...}

method startDocument(Str :$version, Str :$enc, Str :$stand-alone) { self!write('startDocument', $version, $enc, $stand-alone)}
method endDocument { self!write('endDocument')}

method startElement(QName $name) { self!write('startElement', $name)}
method endElement { self!write('endElement')}
method flush { self!write('flush')}

submethod DESTROY {
    with $!raw {
        .flush;
        .Free;
    }
}
