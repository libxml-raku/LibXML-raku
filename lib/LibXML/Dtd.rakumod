use LibXML::Node;

#| LibXML DTD Handling
unit class LibXML::Dtd
    is LibXML::Node;

  =begin pod
  =head2 Synopsis

      use LibXML::Dtd;

      my LibXML::Dtd $dtd .= new($public-id, $system-id);
      my LibXML::Dtd $dtd .= parse: :string($dtd-str);
      my Str $dtdName = $dtd.getName();
      my Str $publicId = $dtd.publicId();
      my Str $systemId = $dtd.systemId();
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
use LibXML::Native;
use LibXML::Parser::Context;
use Method::Also;
use NativeCall;
my subset DocNode of LibXML::Node where {!.defined || .native ~~ xmlDoc};

class ValidContext {
    has xmlValidCtxt $!native;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    multi submethod BUILD( xmlValidCtxt:D :$!native! ) { }
    multi submethod BUILD {
        $!native .= new;
    }

    method validate(DocNode:D :doc($doc-obj)!, LibXML::Dtd :dtd($dtd-obj), Bool() :$check) {
        my xmlDoc:D $doc = .native with $doc-obj;
        my xmlDtd   $dtd = .native with $dtd-obj;
        my $rv;

        my $*XML-CONTEXT = self;
        given xml6_gbl_save_error_handlers() {
            $!native.SetStructuredErrorFunc: &structured-error-cb;
            $rv := $!native.validate(:$doc, :$dtd);

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

method native handles <publicId systemId> {
    callsame() // xmlDtd;
}

=begin pod
    =head2 Methods
=end pod

multi method new(
    Str:D :$type!,
    LibXML::Node :doc($owner), Str:D :$name!,
    Str :$external-id, Str :$system-id, ) {
    my xmlDoc $doc = .native with $owner;
    my xmlDtd:D $native .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.box: $native, :doc($owner);
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
    my xmlDtd:D $native = LibXML::Parser::Context.try: {xmlDtd.parse: :$string, :$enc};
    self.box($native);
}
=begin pod
    =head3 method parse

        method parse(Str :string) returns LibXML::Dtd;

    The same as new() above, except you can parse a DTD from a string. Note that
    parsing from string may fail if the DTD contains external parametric-entity
    references with relative URLs.
=end pod


multi method parse(Str:D :$external-id, Str:D :$system-id) {
    my xmlDtd:D $native = LibXML::Parser::Context.try: {xmlDtd.parse: :$external-id, :$system-id;};
    self.box($native);
}
multi method parse(Str $external-id, Str $system-id) is default {
    self.parse: :$external-id, :$system-id;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) {
    my xmlDtd:D $native = self.native.copy;
    $native.Reference;
    self.clone: :$native;
}

method !valid-ctx { ValidContext.new: :schema(self) }
#| validate a parsed XML document against a DTD
method validate(LibXML::Node:D $node --> UInt) {
    self!valid-ctx.validate($node);
}
  =begin pod
  This function allows one to validate a (parsed) document against the given XML
  Schema. The argument of this function should be a L<LibXML::Document> object.  If this function succeeds, it will return 0, otherwise it will die()
  and report the errors found. Because of this validate() should be always
  evaluated.
  =end pod

#| Returns True if the passed document is valid against the DTD
method is-valid(LibXML::Node:D $node --> Bool) {
    self!valid-ctx.validate($node, :check);
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
