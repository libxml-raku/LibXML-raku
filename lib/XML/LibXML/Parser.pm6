class X::XML::LibXML::Parser is Exception {
    use XML::LibXML::Native;
    use XML::LibXML::Enums;

    has xmlError $.error;
    has Str $.file;
    
    method message {
        my $msg = "Error while parsing {$!file // 'XML document'}\n"
        ~ "XML::LibXML::Parser error";
        with $!error {
            $msg ~= ": $_" with .text;
        }
        $msg;
    }
}

class XML::LibXML::Parser {

use XML::LibXML::Native;
use XML::LibXML::Enums;
use XML::LibXML::Document;

has parserCtxt $!parser-ctx;
has Bool $.html;
has Bool $.line-numbers = False;
has Str $.dir;
has UInt $!flags;

submethod TWEAK(:$!flags = ($!html ?? (HTML_PARSE_RECOVER + HTML_PARSE_NOBLANKS) !! 0)) {
}

method !flag-accessor($flag) is rw {
    Proxy.new(
        FETCH => sub ($) { $!flags +& $flag },
        STORE => sub ($, Bool() $_) {
            if .so {
                $!flags +|= $flag;
            }
            else {
                $!flags -= $flag
                    if $!flags +& $flag
            }
        }
    );
}

method keep-blanks is rw { self!flag-accessor(XML_PARSE_NOBLANKS); }
method expand-entities is rw { self!flag-accessor(XML_PARSE_NOENT); }
method pedantic-parser is rw { self!flag-accessor(XML_PARSE_PEDANTIC); }

method !init-parser returns parserCtxt {
    my parserCtxt $ctx = $!html
       ?? htmlParserCtxt.new
       !! xmlParserCtxt.new;

    die "unable to initialize parser" unless $ctx;
    XML::LibXML::Native.keep-blanks-default = $!flags +& XML_PARSE_NOBLANKS ?? 0 !! 1;
    unless $!flags +& XML_PARSE_DTDLOAD {
        for (XML_PARSE_DTDVALID, XML_PARSE_DTDATTR, XML_PARSE_NOENT ) {
            $!flags -= $_ if $!flags +& $_
        }
    }
    $ctx.use-options($!flags);     # Note: sets ctxt.linenumbers = 1
    $ctx.linenumbers = +$!line-numbers;
    $ctx;
}

multi method parse(Str:D() :$string!,
                   Str :$uri,
                   Str :$enc,
                   Bool :$html) {

    my parserCtxt $ctx = self!init-parser;

    with $ctx.read-doc($string, $uri, $enc, $!flags) {
        $ctx.free;
        XML::LibXML::Document.new: :struct($_);
    }
    else {
        given XML::LibXML::Native.last-error($ctx) -> $error {
            die X::XML::LibXML::Parser.new: :$error;
        }
    }
}

multi method parse(Str:D() :$file!,
                   Str :$uri,
                   Str :$enc,
                   Bool :$html) {

    my parserCtxt $ctx = self!init-parser;

    with $ctx.read-file($file, $uri, $enc, $!flags) {
        $ctx.free;
        XML::LibXML::Document.new: :struct($_);
    }
    else {
        given XML::LibXML::Native.last-error($ctx) -> $error {
            die X::XML::LibXML::Parser.new: :$error;
        }
    }
}

}
