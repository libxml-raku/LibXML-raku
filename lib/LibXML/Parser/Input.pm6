use v6;
use LibXML::Native;

unit class LibXML::Parser::Input;

use LibXML::Parser::Context;

has xmlParserInput $!native;
method native { $!native }

multi sub TWEAK(LibXML::Parser::Context :ctx($ctx-obj)!, Blob:D :$!buf, |c) {
    ...
}

multi sub TWEAK(LibXML::Parser::Context :ctx($ctx-obj)!, Str:D :$!filename, |c) {
    my xmlParserCtxt $ctx = $ctx-obj.native;
    $!native = xmlNewInputFromFile($ctx, $filename)
}


submethod DESTROY {
    .Free with $!native;
}
