use v6;

unit class LibXML::RelaxNG;

use LibXML::Document;
use LibXML::ErrorHandler;
use LibXML::Native;
use LibXML::Native::RelaxNG;
use LibXML::Parser::Context;
has xmlRelaxNG $.native;

my class Parser::Context {
    has xmlRelaxNGParserCtxt $!native;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlRelaxNGParserCtxt:D :$!native! ) {
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
        $!native.SetStructuredErrorFunc: -> xmlRelaxNGParserCtxt $ctx, xmlError:D $err {
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
    has xmlRelaxNGValidCtxt $!native;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    multi submethod BUILD( xmlRelaxNGValidCtxt:D :$!native! ) { }
    multi submethod BUILD( LibXML::RelaxNG:D :schema($_)! ) {
        my xmlRelaxNG:D $schema = .native;
        $!native .= new: :$schema;
    }

    submethod TWEAK {
        $!native.SetStructuredErrorFunc: -> xmlRelaxNGValidCtxt $ctx, xmlError:D $err {
                self.structured-error($err);
        };

    }

    submethod DESTROY {
        .Free with $!native;
    }

    method validate(LibXML::Document:D $_) {
        my xmlDoc:D $doc = .native;
        my $rv := $!native.Validate($doc);
        self.flush-errors;
        $rv;
    }

}

submethod TWEAK(|c) {
    my Parser::Context:D $parser-ctx .= new: |c;
    $!native = $parser-ctx.parse;
}

has ValidContext $!valid-ctx;
method validate(LibXML::Document:D $doc) {
    $_ .= new: :schema(self)
        without $!valid-ctx;
    $!valid-ctx.validate($doc);
}

=begin pod
=head1 NAME

LibXML::RelaxNG - RelaxNG Schema Validation

=head1 SYNOPSIS


  use LibXML::Schema;
  use LibXML;

  my $doc = LibXML.new.parse: :file($url);

  my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
  my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
  my LibXML::RelaxNG $rngschema .= new( :$doc );
  eval { $rngschema->validate( $doc ); };

=head1 DESCRIPTION

The LibXML::RelaxNG class is a tiny frontend to libxml2's RelaxNG
implementation. Currently it supports only schema parsing and document
validation.


=head1 METHODS

=begin item1
new

  my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
  my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
  my LibXML::RelaxNG $rngschema .= new( :$doc );

The constructor of LibXML::RelaxNG may get called with either one of three
parameters. The parameter tells the class from which source it should generate
a validation schema. It is important, that each schema only have a single
source.

The location parameter allows one to parse a schema from the filesystem or a
URL.

The string parameter will parse the schema from the given XML string.

The DOM parameter allows one to parse the schema from a pre-parsed L<<<<<< LibXML::Document >>>>>>.

Note that the constructor will die() if the schema does not meed the
constraints of the RelaxNG specification.

=end item1

=begin item1
validate

  try { $rngschema->validate( $doc ); };

This function allows one to validate a (parsed) document against the given
RelaxNG schema. The argument of this function should be an LibXML::Document
object. If this function succeeds, it will return 0, otherwise it will die()
and report the errors found. Because of this validate() should be always
evaluated.

=end item1

=head1 AUTHORS

Matt Sergeant, 
Christian Glahn, 
Petr Pajas, 

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
