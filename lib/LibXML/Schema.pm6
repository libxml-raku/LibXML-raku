use v6;

unit class LibXML::Schema;

use NativeCall;
use LibXML::Document;
use LibXML::Element;
use LibXML::Native;
use LibXML::Native::Schema;
use LibXML::ParserContext;
has xmlSchema $!struct;

method unbox { $!struct }

my class ParserContext {
    has xmlSchemaParserCtxt $!struct;
    has Pair @!msgs;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlSchemaParserCtxt:D :$!struct! ) {
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
        $!struct.SetStructuredErrorFunc: -> xmlSchemaParserCtxt $ctx, xmlError:D $err {
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
    has xmlSchemaValidCtxt $!struct;
    has Pair @!msgs;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlSchemaValidCtxt:D :$!struct! ) { }
    multi submethod BUILD( LibXML::Schema:D :schema($_)! ) {
        my xmlSchema:D $schema = .unbox;
        $!struct .= new: :$schema;
    }

    submethod TWEAK {
        $!struct.SetStructuredErrorFunc: -> xmlSchemaValidCtxt $ctx, xmlError:D $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!struct;
    }

    multi method validate(LibXML::Document:D $_) {
        my xmlDoc:D $doc = .unbox;
        my $rv := $!struct.ValidateDoc($doc);
        self.flush-errors;
        $rv;
    }

    multi method validate(LibXML::Node:D $_) is default {
        my domNode:D $node = .unbox;
        my $rv := $!struct.ValidateElement($node);
        self.flush-errors;
        $rv;
    }

}

submethod TWEAK(|c) {
    my ParserContext:D $parser-ctx .= new: |c;
    $!struct = $parser-ctx.parse;
}

has ValidContext $!valid-ctx;
method validate(LibXML::Node:D $node) {
    $_ .= new: :schema(self)
        without $!valid-ctx;
    $!valid-ctx.validate($node);
}
