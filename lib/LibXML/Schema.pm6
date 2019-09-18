use v6;

unit class LibXML::Schema;

use LibXML::Document;
use LibXML::Element;
use LibXML::ErrorHandler :&structured-error-cb;
use LibXML::Native;
use LibXML::Native::Schema;
use LibXML::Parser::Context;
has xmlSchema $.native;

my class Parser::Context {
    has xmlSchemaParserCtxt $!native;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;
    has Blob $!buf;

    multi submethod BUILD( xmlSchemaParserCtxt:D :$!native! ) {
    }
    multi submethod BUILD(Str:D :$url!) {
        $!native .= new: :$url;
    }
    multi submethod BUILD(Str:D :location($url)!) {
        self.BUILD: :$url;
    }
    multi submethod BUILD(Blob:D :$!buf!) {
        $!native .= new: :$!buf;
    }
    multi submethod BUILD(Str:D :$string!) {
        self.BUILD: :buf($string.encode);
    }
    multi submethod BUILD(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .native;
        $!native .= new: :$doc;
    }

    submethod TWEAK {
        $!native.SetStructuredErrorFunc: &structured-error-cb;
    }

    submethod DESTROY {
        $!buf = Nil;
        .Free with $!native;
    }

    method parse {
        my $*XML-CONTEXT = self;
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
        $!native.SetStructuredErrorFunc: &structured-error-cb;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    multi method validate(LibXML::Document:D $_, Bool() :$check) {
        my $*XML-CONTEXT = self;
        my xmlDoc:D $doc = .native;
        my $rv := $!native.ValidateDoc($doc);
	$rv := $!errors.is-valid
            if $check;
        self.flush-errors;
        $rv;
    }

    multi method validate(LibXML::Element:D $_, Bool() :$check) is default {
        my xmlNode:D $node = .native;
        my $rv := $!native.ValidateElement($node);
	$rv := $!errors.is-valid
            if $check;
        self.flush-errors;
        $rv;
    }
}

submethod TWEAK(|c) {
    my Parser::Context:D $parser-ctx .= new: |c;
    $!native = $parser-ctx.parse;
}

submethod DESTROY {
    .Free with $!native;
}

method !valid-ctx { ValidContext.new: :schema(self) }
method validate(LibXML::Node:D $node) {
    self!valid-ctx.validate($node);
}
method is-valid(LibXML::Node:D $node) {
    self!valid-ctx.validate($node, :check);
}

=begin pod
=head1 NAME

LibXML::Schema - XML Schema Validation

=head1 SYNOPSIS



  use LibXML::Schema;
  use LibXML;

  my $doc = LibXML.new.parse: :file($url);

  my LibXML::Schema $xmlschema  .= new( location => $filename_or_url );
  my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring );
  try { $xmlschema.validate( $doc ); };

=head1 DESCRIPTION

The LibXML::Schema class is a tiny frontend to libxml2's XML Schema
implementation. Currently it supports only schema parsing and document
validation. libxml2 only supports decimal types up to 24 digits
(the standard requires at least 18). 


=head1 METHODS

=begin item1
new

  my LibXML::Schema $xmlschema  .= new( location => $filename_or_url );
  my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring );

The constructor of LibXML::Schema may get called with either one of two
parameters. The parameter tells the class from which source it should generate
a validation schema. It is important, that each schema only have a single
source.

The location parameter allows one to parse a schema from the filesystem or a
URL.

The string parameter will parse the schema from the given XML string.

Note that the constructor will die() if the schema does not meed the
constraints of the XML Schema specification.

=end item1

=begin item1
validate

  try { $xmlschema.validate( $doc ); };

This function allows one to validate a (parsed) document against the given XML
Schema. The argument of this function should be a L<<<<<< LibXML::Document >>>>>> object. If this function succeeds, it will return 0, otherwise it will die()
and report the errors found. Because of this validate() should be always
evaluated.

=end item1

=begin item1
is-valid

  my Bool $valid = $xmlschema.is-valid($doc);

Returns either True or False depending on whether the passed Document is valid or not.

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
