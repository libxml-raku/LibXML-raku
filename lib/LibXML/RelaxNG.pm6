use v6;

unit class LibXML::RelaxNG;

use LibXML::Native;
use LibXML::ParserContext;
use NativeCall;

my class ParserContext {
    has xmlRelaxNGParserCtxt $!struct;
    has Pair @!msgs;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    submethod TWEAK( xmlRelaxNGParserCtxt:D :$!struct! ) {
        $!struct.SetStructuredErrorFunc: -> xmlRelaxNGParserCtxt:D $ctx, xmlError $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!struct;
    }

    method parse {
        my $rv := $!struct.Parse;

        self.flush-errors;

        $rv;
    }

}

multi method parse(Str:D :$url!) {
    my xmlRelaxNGParserCtxt:D $struct .= new: :$url;
    my ParserContext $ctx .= new: :$struct;
    $ctx.parse;
}

multi method parse(Str:D :location($url)!) {
    self.parse: :$url;
}

multi method parse(Blob:D :$buf!) {
    my xmlRelaxNGParserCtxt:D $struct .= new: :$buf;
    my ParserContext $ctx .= new: :$struct;
    $ctx.parse;
}

multi method parse(Str:D :$string!) {
    my Blob:D $buf = $string.encode;
    self.parse: :$buf;
}
