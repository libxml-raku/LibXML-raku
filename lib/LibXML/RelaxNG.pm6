use v6;

unit class LibXML::RelaxNG;

use NativeCall;
use LibXML::Document;
use LibXML::Native;
use LibXML::ParserContext;
has xmlRelaxNG $!struct;

method unbox { $!struct }

sub callback(&s) {
    -> |c {
        CATCH { default { warn $_ } }
        s(|c)
    }
}

my class ParserContext {
    has xmlRelaxNGParserCtxt $!struct;
    has Pair @!msgs;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlRelaxNGParserCtxt:D :$!struct! ) {
    }
    multi submethod BUILD(Str:D :$url!) {
        $!struct .= new: :$url;
    }
    multi submethod BUILD(Str:D :location($url)!) {
        self.BUILD: :$url;
    }
    multi submethod BUILD(Blob:D :$buf!) {
        $!struct .= new: :$buf;
    }
    multi submethod BUILD(Str:D :$string!) {
        my Blob:D $buf = $string.encode;
        self.BUILD: :$buf;
    }
    multi submethod BUILD(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .unbox;
        $!struct .= new: :$doc;
    }

    submethod TWEAK {
        $!struct.SetStructuredErrorFunc: -> xmlRelaxNGParserCtxt $ctx, xmlError:D $err {
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

my class ValidContext {
    has xmlRelaxNGValidCtxt $!struct;
    has Pair @!msgs;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlRelaxNGValidCtxt:D :$!struct! ) { }
    multi submethod BUILD( LibXML::RelaxNG:D :schema($_)! ) {
        my xmlRelaxNG:D $schema = .unbox;
        $!struct .= new: :$schema;
    }

    submethod TWEAK {
        $!struct.SetStructuredErrorFunc: -> xmlRelaxNGValidCtxt $ctx, xmlError:D $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!struct;
    }

    method validate(LibXML::Document:D $_) {
        my xmlDoc:D $doc = .unbox;
        my $rv := $!struct.Validate($doc);
        self.flush-errors;
        $rv;
    }

}

submethod TWEAK(|c) {
    my ParserContext:D $parser-ctx .= new: |c;
    $!struct = $parser-ctx.parse;
}

method validate(LibXML::Document:D $doc) {
    my ValidContext $valid-ctx .= new: :schema(self);
    $valid-ctx.validate($doc);
}
