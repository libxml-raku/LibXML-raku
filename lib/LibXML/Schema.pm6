use v6;

unit class LibXML::Schema;

use LibXML::Document;
use LibXML::Element;
use LibXML::ErrorHandler;
use LibXML::Native;
use LibXML::Native::Schema;
use LibXML::ParserContext;
has xmlSchema $.native;

my class ParserContext {
    has xmlSchemaParserCtxt $!native;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlSchemaParserCtxt:D :$!native! ) {
    }
    multi submethod BUILD(Str:D :$url!) {
        $!native .= new: :$url;
    }
    multi submethod BUILD(Str:D :location($url)!) {
        self.BUILD: :$url;
    }
    multi submethod BUILD(Blob:D :$buf!) {
        $!native .= new: :$buf;
    }
    multi submethod BUILD(Str:D :$string!) {
        my Blob:D $buf = $string.encode;
        self.BUILD: :$buf;
    }
    multi submethod BUILD(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .native;
        $!native .= new: :$doc;
    }

    submethod TWEAK {
        $!native.SetStructuredErrorFunc: -> xmlSchemaParserCtxt $ctx, xmlError:D $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!native;
    }

    method parse {
        my $rv := $!native.Parse;
        self.flush-errors;
        $rv;
    }

}

my class ValidContext {
    has xmlSchemaValidCtxt $!native;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlSchemaValidCtxt:D :$!native! ) { }
    multi submethod BUILD( LibXML::Schema:D :schema($_)! ) {
        my xmlSchema:D $schema = .native;
        $!native .= new: :$schema;
    }

    submethod TWEAK {
        $!native.SetStructuredErrorFunc: -> xmlSchemaValidCtxt $ctx, xmlError:D $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!native;
    }

    multi method validate(LibXML::Document:D $_) {
        my xmlDoc:D $doc = .native;
        my $rv := $!native.ValidateDoc($doc);
        self.flush-errors;
        $rv;
    }

    multi method validate(LibXML::Node:D $_) is default {
        my domNode:D $node = .native;
        my $rv := $!native.ValidateElement($node);
        self.flush-errors;
        $rv;
    }

}

submethod TWEAK(|c) {
    my ParserContext:D $parser-ctx .= new: |c;
    $!native = $parser-ctx.parse;
}

has ValidContext $!valid-ctx;
method validate(LibXML::Node:D $node) {
    $_ .= new: :schema(self)
        without $!valid-ctx;
    $!valid-ctx.validate($node);
}
