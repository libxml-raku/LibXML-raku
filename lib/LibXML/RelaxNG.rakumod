use v6;

#| RelaxNG Schema Validation
unit class LibXML::RelaxNG;

    =head2 Synopsis

        =begin code :lang<raku>
        use LibXML::RelaxNG;
        use LibXML;

        my $doc = LibXML.new.parse: :file($url);

        my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
        my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
        my LibXML::RelaxNG $rngschema .= new( :$doc );
        try { $rngschema.validate( $doc ); };
        if  $rngschema.is-valid( $doc ) {...}
        if $doc ~~ $rngschema { ... }
        =end code

    =head2 Description

    =para
    The LibXML::RelaxNG class is a tiny frontend to libxml2's RelaxNG
    implementation. Currently it supports only schema parsing and document
    validation.

    =head2 Methods

use LibXML::Document;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::_Options;
use LibXML::Raw;
use LibXML::Raw::RelaxNG;
use LibXML::Parser::Context;
use LibXML::Config;
use Method::Also;

has xmlRelaxNG $.raw;

my class Parser::Context {
    has xmlRelaxNGParserCtxt $!raw;
    has Blob $!buf;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod BUILD( xmlRelaxNGParserCtxt:D :$!raw! ) {
    }
    multi submethod BUILD(Str:D :$url!) {
        $!raw .= new: :$url;
    }
    multi submethod BUILD(Str:D :location($url)!) {
        self.BUILD: :$url;
    }
    multi submethod BUILD(Blob:D :$!buf!) {
        $!raw .= new: :$!buf;
    }
    multi submethod BUILD(Str:D :$string!) {
        self.BUILD: :buf($string.encode);
    }
    multi submethod BUILD(LibXML::Document:D :doc($_)!) {
        my xmlDoc:D $doc = .raw;
        $!raw .= new: :$doc;
    }

    submethod DESTROY {
        $!buf = Nil;
        .Free with $!raw;
    }

    method parse {
        my $rv;

        LibXML::Config.protect: sub () is hidden-from-backtrace {
            my $*XML-CONTEXT = self;
            my $handlers = xml6_gbl_save_error_handlers();
            $!raw.SetStructuredErrorFunc: &structured-error-cb;
            $!raw.SetParserErrorFunc: &structured-error-cb;

            $rv := $!raw.Parse;

            xml6_gbl_restore_error_handlers($handlers);
            self.flush-errors;
        }
        $rv;
    }

}

my class ValidContext {
    has xmlRelaxNGValidCtxt $!raw;
    # for the LibXML::ErrorHandling role
    has $.sax-handler;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod BUILD( xmlRelaxNGValidCtxt:D :$!raw! ) { }
    multi submethod BUILD( LibXML::RelaxNG:D :schema($_)! ) {
        my xmlRelaxNG:D $schema = .raw;
        $!raw .= new: :$schema;
    }

    submethod DESTROY {
        .Free with $!raw;
    }

    method validate(LibXML::Document:D $doc, Bool() :$check) is hidden-from-backtrace {
        my $rv;

        LibXML::Config.protect: sub () is hidden-from-backtrace {
            my $*XML-CONTEXT = self;
            my $handlers = xml6_gbl_save_error_handlers();
            $!raw.SetStructuredErrorFunc: &structured-error-cb;

            $rv := $!raw.ValidateDoc($doc.raw);

            xml6_gbl_restore_error_handlers($handlers);
	    $rv := self.validity-check
                if $check;
            self.flush-errors;
        }

        $rv;
    }

    method is-valid(LibXML::Document:D $_) {
        self.validate($_, :check);
    }

}

submethod TWEAK(|c) {
    my Parser::Context $parser-ctx .= new: |c;
    $!raw = $parser-ctx.parse;
}
=begin pod
    =head3 method new

        multi method new( :location($filename_or_url) ) returns LibXML::RelaxNG;
        multi method new( :string($xml-schema-string) ) returns LibXML::RelaxNG;
        multi method new( LibXML::Document :$doc ) returns LibXML::RelaxNG;

    The constructors for LibXML::RelaxNG may get called with either one of three
    parameters. The parameter tells the class from which source it should generate
    a validation schema. It is important, that each schema only have a single
    source.

    The `:location` parameter allows one to parse a schema from the filesystem or a
    URL.

    The `:string` parameter will parse the schema from the given XML string.

    The `:doc` parameter allows one to parse the schema from a pre-parsed L<<<<<<LibXML::Document>>>>>>.

    Note that the constructor will die() if the schema does not meed the
    constraints of the RelaxNG specification.
=end pod

method !valid-ctx($schema:) { ValidContext.new: :$schema }
method validate(LibXML::Document:D $doc) is hidden-from-backtrace {
    self!valid-ctx.validate($doc);
}
=begin pod
    =head3 method validate

        try { $rngschema->validate( $doc ); };

    This function allows one to validate a (parsed) document against the given
    RelaxNG schema. The argument of this function should be an LibXML::Document
    object. If this function succeeds, it will return 0, otherwise it will throw,
    reporting the found. Because of this validate() should be always be execute in
    a `try` block or in the scope of a `CATCH` block.
=end pod

method is-valid(LibXML::Document:D $doc) {
    self!valid-ctx.is-valid($doc);
}
=begin pod
    =head3 method is-valid

        method is-valid(LibXML::Document $doc) returns Bool;
        $valid = $doc ~~ $rngschema;

    Returns either True or False depending on whether the passed Document is valid or not.
=end pod

#| Returns True if the document validates against the given schema
multi method ACCEPTS(LibXML::RelaxNG:D: LibXML::Document:D $doc --> Bool) {
    self.is-valid($doc);
}
=para Example:

    =begin code :lang<raku>
    $valid = $doc ~~ $rngschema;
    =end code

submethod DESTROY {
    .Free with $!raw;
}

=begin pod

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
