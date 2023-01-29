unit class LibXML::Writer;

use LibXML::_Configurable;
also does LibXML::_Configurable;

use LibXML::Raw;
use LibXML::Raw::TextWriter;
use LibXML::Types :QName, :NCName;
use Method::Also;
use NativeCall;

has xmlTextWriter $.raw is rw is built;

#| Ensure libxml2 has been compiled with the tex-writer enabled
method have-writer {
    ? xml6_config_have_libxml_writer();
}

method !write(Str:D $op, |c) is hidden-from-backtrace {
    my Int $rv := $!raw."$op"(|c);
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
method close {
    with $!raw {
        .flush;
        .Free;
        $_ = Nil;
    }
}

submethod DESTROY {
    self.close;
}
