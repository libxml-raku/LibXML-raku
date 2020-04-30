use v6;

unit class LibXML::Schema;

use LibXML::Document;
use LibXML::Element;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::_Options;
use LibXML::Native;
use LibXML::Native::Schema;
use LibXML::Parser::Context;
use Method::Also;

has xmlSchema $.native;

my class Parser::Context {
    has xmlSchemaParserCtxt $!native;
    has Blob $!buf;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings, $.network) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings, :network)];
    also does LibXML::ErrorHandling;

    multi submethod TWEAK( xmlSchemaParserCtxt:D :$!native! ) {
    }
    multi submethod TWEAK(Str:D :$url!) {
        $!native .= new: :$url;
    }
    multi submethod TWEAK(Str:D :location($url)!) {
        self.TWEAK: :$url;
    }
    multi submethod TWEAK(Blob:D :$!buf!) {
        $!native .= new: :$!buf;
    }
    multi submethod TWEAK(Str:D :$string!) {
        self.TWEAK: :buf($string.encode);
    }
    multi submethod TWEAK(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .native;
        $!native .= new: :$doc;
    }

    submethod DESTROY {
        $!buf = Nil;
        .Free with $!native;
    }

    method parse {
        my $*XML-CONTEXT = self;
        my $rv;

        my $ext-loader-changed = xmlExternalEntityLoader::set-networked(+$!network.so);
        given xml6_gbl_save_error_handlers() {
            $!native.SetStructuredErrorFunc: &structured-error-cb;
            $!native.SetParserErrorFunc: &structured-error-cb;

            $rv := $!native.Parse;

            xml6_gbl_restore_error_handlers($_);
        }

        if $ext-loader-changed {
            xmlExternalEntityLoader::set-networked(+!$!network.so);
        }

        self.flush-errors;
        $rv;
    }

}

my class ValidContext {
    has xmlSchemaValidCtxt $!native;
    # for the LibXML::ErrorHandling role
    has $.sax-handler;
    method recover is also<suppress-errors suppress-warnings> { False }
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :sax-handler, :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod TWEAK( xmlSchemaValidCtxt:D :$!native! ) { }
    multi submethod TWEAK( LibXML::Schema:D :schema($_)! ) {
        my xmlSchema:D $schema = .native;
        $!native .= new: :$schema;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    multi method validate(LibXML::Document:D $_, Bool() :$check) {
        my $*XML-CONTEXT = self;
        my xmlDoc:D $doc = .native;
        my $rv;
        given xml6_gbl_save_error_handlers() {
        $!native.SetStructuredErrorFunc: &structured-error-cb;
            $rv := $!native.ValidateDoc($doc);
	    $rv := self.validity-check
                if $check;
            xml6_gbl_restore_error_handlers($_)
        }
        self.flush-errors;
        $rv;
    }

    multi method validate(LibXML::Element:D $_, Bool() :$check) is default {
        my xmlNode:D $node = .native;
        my $rv := $!native.ValidateElement($node);
	$rv := self.is-valid
            if $check;
        self.flush-errors;
        $rv;
    }
}

submethod TWEAK(|c) {
    my Parser::Context $parser-ctx .= new: |c;
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

multi method ACCEPTS(LibXML::Schema:D: LibXML::Node:D $node) {
    self.is-valid($node);
}

=begin pod
=head1 NAME

LibXML::Schema - XML Schema Validation

=head1 SYNOPSIS

  =begin code :lang<raku>
  use LibXML::Schema;
  use LibXML;

  my $doc = LibXML.new.parse: :file($url);

  my LibXML::Schema $xmlschema  .= new( location => $filename_or_url );
  my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring );
  try { $xmlschema.validate( $doc ); };
  if $doc ~~ $xmlschema { ... }
  =end code

=head1 DESCRIPTION

The LibXML::Schema class is a tiny frontend to libxml2's XML Schema
implementation. Currently it supports only schema parsing and document
validation. libxml2 only supports decimal types up to 24 digits
(the standard requires at least 18). 


=head1 METHODS

=begin item1
new
    =begin code :lang<raku>
  my LibXML::Schema $xmlschema  .= new( location => $filename_or_url, :network );
  my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring, :network );
    =end code
The constructor of LibXML::Schema may get called with either one of two
parameters. The parameter tells the class from which source it should generate
a validation schema. It is important, that each schema only have a single
source.

The location parameter allows one to parse a schema from the filesystem or a
URL.

The `:network` flag effects processing of `xsd:import` directives. By default
this is disabled, unless a custom External Entity Loader has been installed
via the `LibXML::Config.external-entity-loader` method. More detailed control
can then be achieved by setting up a custom entity loader, or by using input callbacks configured via the L<LibXML::Config> `.input-callbacks` method.

The string parameter will parse the schema from the given XML string.

Note that the constructor will die() if the schema does not meed the
constraints of the XML Schema specification.

=end item1

=begin item1
validate
    =begin code :lang<raku>
    try { $xmlschema.validate( $doc ); };
    =end code
This function allows one to validate a (parsed) document against the given XML
Schema. The argument of this function should be a L<<<<<< LibXML::Document >>>>>> object. If this function succeeds, it will return 0, otherwise it will die()
and report the errors found. Because of this validate() should be always
evaluated.

=end item1

=begin item1
is-valid / ACCEPTS
    =begin code :lang<raku>
    my Bool $valid = $xmlschema.is-valid($doc);
    $valid = $doc ~~ $xmlschema;
    =end code
Returns either True or False depending on whether the passed Document is valid or not.

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
