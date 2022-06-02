#| XML Schema Validation
unit class LibXML::Schema;

use LibXML::_Validator;
also does LibXML::_Validator;

=begin pod

    =head2 Synopsis

        use LibXML::Schema;
        use LibXML;

        my $doc = LibXML.new.parse: :file($url);

        my LibXML::Schema $xmlschema  .= new( location => $filename_or_url );
        my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring );
        try { $xmlschema.validate( $doc ); };
        if $doc ~~ $xmlschema { ... }

    =head2 Description

    The LibXML::Schema class is a tiny frontend to libxml2's XML Schema
    implementation. Currently it supports only schema parsing and document
    validation. libxml2 only supports decimal types up to 24 digits
    (the standard requires at least 18).

    =head2 Methods

=end pod

use LibXML::Document;
use LibXML::Element;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::_Configurable;
use LibXML::_Options;
use LibXML::Raw;
use LibXML::Raw::Schema;
use LibXML::Parser::Context;
use Method::Also;
use LibXML::Config :&protected;

has xmlSchema $.raw;

my class Parser::Context {
    has xmlSchemaParserCtxt $!raw;
    has Blob $!buf;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings, $.network) is rw;
    also does LibXML::_Configurable;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings, :network)];
    also does LibXML::ErrorHandling;

    multi submethod TWEAK( xmlSchemaParserCtxt:D :$!raw! ) {
    }
    multi submethod TWEAK(Str:D :$url!) {
        $!raw .= new: :$url;
    }
    multi submethod TWEAK(Str:D :location($url)!) {
        self.TWEAK: :$url;
    }
    multi submethod TWEAK(Blob:D :$!buf!) {
        $!raw .= new: :$!buf;
    }
    multi submethod TWEAK(Str:D :$string!) {
        self.TWEAK: :buf($string.encode);
    }
    multi submethod TWEAK(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .raw;
        $!raw .= new: :$doc;
    }

    submethod DESTROY {
        $!buf = Nil;
        .Free with $!raw;
    }

    method parse {
        my $rv;

        protected sub () is hidden-from-backtrace {
            my $*XML-CONTEXT = self;

            my $handlers = xml6_gbl_save_error_handlers();
            $!raw.SetStructuredErrorFunc: &structured-error-cb;
            $!raw.SetParserErrorFunc: &structured-error-cb;
            my @prev = self.config.setup();
            xmlExternalEntityLoader::set-networked(+$!network.so);

            $rv := $!raw.Parse;

            self.flush-errors;

            LEAVE {
                self.config.restore(@prev);
                xml6_gbl_restore_error_handlers($handlers);
             }
        }

        $rv;
    }

}

my class ValidContext {
    has xmlSchemaValidCtxt $!raw;
    # for the LibXML::ErrorHandling role
    has $.sax-handler;
    method recover is also<suppress-errors suppress-warnings> { False }
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Configurable;
    also does LibXML::_Options[%( :sax-handler, :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod TWEAK( xmlSchemaValidCtxt:D :$!raw! ) { }
    multi submethod TWEAK( LibXML::Schema:D :schema($_)! ) {
        my xmlSchema:D $schema = .raw;
        $!raw .= new: :$schema;
    }

    submethod DESTROY {
        .Free with $!raw;
    }

    multi method validate(LibXML::Document:D $_, Bool() :$check) is hidden-from-backtrace {
        my xmlDoc:D $doc = .raw;
        my $rv;

        protected sub () is hidden-from-backtrace {
            my $*XML-CONTEXT = self;
            my $handlers = xml6_gbl_save_error_handlers();
            $!raw.SetStructuredErrorFunc: &structured-error-cb;
            my @prev = self.config.setup();
            $rv := $!raw.ValidateDoc($doc);

	    $rv := self.validity-check
                if $check;
            self.flush-errors;
            LEAVE {
                self.config.restore(@prev);
                xml6_gbl_restore_error_handlers($handlers);
            }
        }

        $rv;
    }

    multi method validate(LibXML::Element:D $_, Bool() :$check) is hidden-from-backtrace {
        my xmlNode:D $node = .raw;
        my $rv := $!raw.ValidateElement($node);
	$rv := self.is-valid
            if $check;
        self.flush-errors;
        $rv;
    }
}

submethod TWEAK(|c) {
    my Parser::Context $parser-ctx .= new: |c;
    $!raw = $parser-ctx.parse;
}
=begin pod
    =head3 method new

        multi method new( Str :$location!, *%opts ) returns LibXML::Schema
        multi method new( Str :string!,  *%opts ) returns LibXML::Schema
        multi method new( LibXML::Document :$doc!,  *%opts ) returns LibXML::Schema

    The constructor of LibXML::Schema may get called with either one of two
    parameters. The parameter tells the class from which source it should generate
    a validation schema. It is important, that each schema only have a single
    source.

    The location parameter allows one to parse a schema from the filesystem or a
    URL.

    The `:network` flag effects processing of `xsd:import` directives. By default
    this is disabled, unless a custom External Entity Loader has been installed
    via the L<LibXML::Config>`.external-entity-loader` method. More detailed control
    can then be achieved by setting up a custom entity loader, or by using input callbacks configured via the L<LibXML::Config> `.input-callbacks` method.

    The string parameter will parse the schema from the given XML string.

    Note that the constructor will die() if the schema does not meet the
    constraints of the XML Schema specification.
=end pod

submethod DESTROY {
    .Free with $!raw;
}

method !valid-ctx($schema: :$config!) { ValidContext.new: :$schema, :$config }
method validate(LibXML::Node:D $node, Bool :$check, LibXML::Config :$config) is hidden-from-backtrace {
    self!valid-ctx(:$config).validate($node, :$check);
}
=begin pod
    =head3 method validate

        multi method validate(LibXML::Document $doc) returns Int
        multi method validate(LibXML::Element $elem) returns Int
        try { $xmlschema.validate( $doc ); };

    This function allows one to validate a document, or a root element
    against the given XML Schema. If this function succeeds, it will
    return 0, otherwise it will die() and report the errors found.
=end pod

method is-valid(LibXML::Node:D $node, LibXML::Config :$config --> Bool) {
    self!valid-ctx(:$config).validate($node, :check);
}
=begin pod
    =head3 method is-valid

        multi method is-valid(LibXML::Document $doc) returns Bool
        multi method is-valid(LibXML::Element $elem) returns Bool

=end pod

#| Returns either True or False depending on whether the Document or Element is valid or not.
multi method ACCEPTS(LibXML::Schema:D: LibXML::Node:D $node --> Bool) {
    self.is-valid($node);
}
=para Example:
    =begin code :lang<raku>
    $valid = $doc ~~ $xmlschema;
    =end code

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
