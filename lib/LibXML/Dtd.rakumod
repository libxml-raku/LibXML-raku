use LibXML::Node;
use W3C::DOM;

#| LibXML DTD Handling
unit class LibXML::Dtd
    is LibXML::Node
    does W3C::DOM::DocumentType;

  =begin pod
  =head2 Synopsis

      use LibXML::Dtd;
      use LibXML::Dtd::Notation;

      my LibXML::Dtd $dtd .= new($public-id, $system-id);
      my LibXML::Dtd $dtd .= parse: :string($dtd-str);

      # Information retrieval
      my Str $dtdName = $dtd.getName();
      my Str $publicId = $dtd.publicId();
      my Str $systemId = $dtd.systemId();
      my Bool $is-html = $dtd.is-XHTML;
      my $notations = $dtd.notations;
      my LibXML::Dtd::Notation $foo = $notations<foo>;

      # Validation
      try { $dtd.validate($doc) };
      my Bool $valid = $dtd.is-valid($doc);
      if $doc ~~ $dtd { ... } # if doc is valid against the DTD

  =head2 Description

  This class holds a DTD. You may parse a DTD from either a string, or from an
  external SYSTEM identifier.

  No support is available as yet for parsing from a filehandle.

  LibXML::Dtd is a sub-class of L<LibXML::Node>, so all the methods available to nodes (particularly Str()) are available
  to Dtd objects.
  =end  pod

use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::_Options;
use LibXML::Raw;
use LibXML::Parser::Context;
use LibXML::Entity;
use LibXML::Dtd::AttrDecl;
use LibXML::Dtd::ElementDecl;
use LibXML::Dtd::Notation;
use LibXML::HashMap;
use Method::Also;
use NativeCall;

has xmlDtd $.raw is built handles <systemId publicId>;

constant DocNode = W3C::DOM::Document;

class ValidContext {
    has xmlValidCtxt $!raw;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod BUILD( xmlValidCtxt:D :$!raw! ) { }
    multi submethod BUILD {
        $!raw .= new;
    }

    method validate(DocNode:D :doc($doc-obj)!, LibXML::Dtd :dtd($dtd-obj), Bool() :$check) is hidden-from-backtrace {
        my xmlDoc:D $doc = .raw with $doc-obj;
        my xmlDtd   $dtd = .raw with $dtd-obj;
        with $dtd {
            # redo internal validation
            $_ = Nil
               if .isSameNode($doc.getInternalSubset)
               or .isSameNode($doc.getExternalSubset);
        }
        my $rv;

        my $*XML-CONTEXT = self;
        given xml6_gbl_save_error_handlers() {
            $!raw.SetStructuredErrorFunc: &structured-error-cb;
            $rv := $!raw.validate(:$doc, :$dtd);

	    $rv := self.validity-check
                if $check;

            xml6_gbl_restore_error_handlers($_);
        }
        self.flush-errors;

        ? $rv;
    }

    method is-valid(|c) {
        self.validate(:check, |c);
    }

}

=begin pod
    =head2 Methods
=end pod

multi method new(
    Str:D :$type!,
    LibXML::Node :doc($owner), Str:D :$name!,
    Str :$external-id, Str :$system-id, ) {
    my xmlDoc $doc = .raw with $owner;
    my xmlDtd:D $new-dtd .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.box: $new-dtd;
}

# for Perl 5 compat
multi method new($external-id, $system-id) {
    self.parse(:$external-id, :$system-id);
}

=begin pod
    =head3 method new

        # preferred constructor
        multi method new(Str :$public-id, Str :$system-id) returns LibXML::Dtd
        # for Perl compat
        multi method new(Str $public-id, Str $system-id) returns LibXML::Dtd

    Parse a DTD from the system identifier, and return a DTD object that you can
    pass to $doc.is-valid() or $doc.validate().

        my $dtd = LibXML::Dtd.new(
                              "SOME // Public / ID / 1.0",
                              "test.dtd"
                                        );
        my $doc = LibXML.load: :file("test.xml");
        $doc.validate($dtd);

        $doc.is-valid($dtd);
        #-OR-
        $doc ~~ $dtd;

=end pod

multi method parse(Str :$string!, xmlEncodingStr:D :$enc = 'UTF-8') {
    my xmlDtd:D $raw = LibXML::Parser::Context.try: {xmlDtd.parse: :$string, :$enc};
    self.box($raw);
}
=begin pod
    =head3 method parse

        method parse(Str :string) returns LibXML::Dtd;

    =para The same as new() above, except you can parse a DTD from a string. Note that
    parsing from string may fail if the DTD contains external parametric-entity
    references with relative URLs.
=end pod


multi method parse(Str:D :$external-id, Str:D :$system-id) {
    my xmlDtd:D $raw = LibXML::Parser::Context.try: {xmlDtd.parse: :$external-id, :$system-id;};
    self.box($raw);
}
multi method parse(Str $external-id, Str $system-id) is default {
    self.parse: :$external-id, :$system-id;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) {
    my xmlDtd:D $raw = self.raw.copy;
    $raw.Reference;
    self.clone: :$raw;
}

method !valid-ctx($schema:) { ValidContext.new: :$schema }

method validate(LibXML::Dtd:D $dtd: DocNode:D $doc = $.ownerDocument --> UInt) is hidden-from-backtrace {
    self!valid-ctx.validate(:$dtd, :$doc);
}
  =begin pod
  =head3 method validate

      method validate($doc = $.ownerDocument --> UInt)

  =para This function allows one to validate a (parsed) document against the given XML
  Schema. The argument of this function should be a L<LibXML::Document> object.  If this function succeeds, it will return 0, otherwise it will die()
  and report the errors found. Because of this validate() should be always
  evaluated.
  =end pod

#| Returns True if the passed document is valid against the DTD
method is-valid(LibXML::Dtd:D $dtd: DocNode:D $doc --> Bool) {
    self!valid-ctx.validate(:$dtd, :$doc, :check);
}

#| Returns True if the publicId or systemId match an XHTML identifier
method is-XHTML(--> Bool) {
    return [False, True][ $.raw.IsXHTML ] // Bool;
}
=para Returns False if the Id's don't match or Bool:U if the DtD lack either a publicId or systemId

# NYI DOM Level-2 methods
method internalSubset {
    die X::NYI.new
}

has LibXML::HashMap[LibXML::Dtd::Notation] $!notations;
method notations {
    $!notations //= LibXML::HashMap[LibXML::Dtd::Notation, :ro].new :raw($_)
        with $!raw.notations;
}

has LibXML::HashMap[LibXML::Dtd::ElementDecl] $!elements;
method element-decls {
    $!elements //= LibXML::HashMap[LibXML::Dtd::ElementDecl, :ro].new :raw($_)
        with $!raw.elements;
}

has LibXML::HashMap[LibXML::Dtd::AttrDecl] $!attributes;
method attribute-decls {
    $!attributes //= LibXML::HashMap[LibXML::Dtd::AttrDecl, :ro].new :raw($_)
        with $!raw.attributes;
}

has LibXML::HashMap[LibXML::Entity] $!entities;
method entities {
    $!entities //= LibXML::HashMap[LibXML::Entity, :ro].new :raw($_)
        with $!raw.entities;
}

multi method ACCEPTS(LibXML::Dtd:D: LibXML::Node:D $node) {
    self.is-valid($node);
}

=begin pod
    =head3 method getName

        method getName() returns Str

    Returns the name of DTD; i.e., the name immediately following the DOCTYPE
    keyword.

    =head3 method publicId

        method publicId() returns Str

    Returns the public identifier of the external subset.


    =head3 method systemId

        method systemId() returns Str

    Returns the system identifier of the external subset.
=end pod

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
