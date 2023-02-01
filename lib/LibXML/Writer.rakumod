#| Interface to libxml2 stream writer
unit class LibXML::Writer;

use LibXML::_Configurable;
also does LibXML::_Configurable;

=begin pod

use LibXML::Writer::Buffer; # write to a string

=end pod

use LibXML::Raw;
use LibXML::Raw::TextWriter;
use LibXML::Types :QName, :NCName;
use LibXML::ErrorHandling;
use Method::Also;
use NativeCall;

has xmlTextWriter $.raw is rw is built;

#| Ensure libxml2 has been compiled with the text-writer enabled
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
    Method $m  where {.yada && .count <= 1},
    :$writer-raw!) {
    my $name := $m.name;
    $m.wrap(method (|c) is hidden-from-backtrace { self!write($name, |c) })
}

## traits not working
## method startElement(QName $name) is writer-raw {...}

method startDocument(Str :$version, Str :$enc, Str :$stand-alone) { self!write('startDocument', $version, $enc, $stand-alone)}
method endDocument { self!write('endDocument')}

method startElement(QName $name) { self!write('startElement', $name)}
method startElementNS(NCName $local-name, Str :$prefix, Str :$uri) { self!write('startElementNS', $prefix, $local-name, $uri)}
method endElement { self!write('endElement')}
method writeElement(QName $name, Str $content?) { self!write('writeElement', $name, $content)}
method writeElementNS(NCName $local-name, Str $content = '', Str :$prefix, Str :$uri) { self!write('writeElementNS', $prefix, $local-name, $uri, $content)}

method writeAttribute(QName $name, Str $content) { self!write('writeAttribute', $name, $content)}
method writeAttributeNS(NCName $local-name, Str $content, Str :$prefix, Str :$uri) { self!write('writeAttributeNS', $prefix, $local-name, $uri, $content)}

multi method writeComment(Str:D $content where .contains('-->')) {
    $content.split(/'-->'/).map({ $.writeComment($_) }).join;
}
multi method writeComment(Str:D $content) { self!write('writeComment', $content)}

method writeText(Str:D $content) { self!write('writeString', $content)}
multi method writeCDATA(Str:D $content where .contains(']]>')) {
    $content.split(/<?after ']'><?before ']>'>/).map({ $.writeCDATA($_) }).join;
}
multi method writeCDATA(Str:D $content) { self!write('writeCDATA', $content)}
method writeRaw(Str:D $content) { self!write('writeRaw', $content)}

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
