use LibXML::Node;

unit class LibXML::Dtd
    is LibXML::Node;

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

    submethod DESTROY {
        .Free with $!native;
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

multi submethod TWEAK(xmlDtd:D :native($)!) { }
multi submethod TWEAK(
    Str:D :$type!,
    LibXML::Node :doc($owner), Str:D :$name!,
    Str :$external-id, Str :$system-id, ) {
    my xmlDoc $doc = .native with $owner;
    my xmlDtd:D $dtd-struct .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.set-native($dtd-struct);
}

# for Perl 5 compat
multi method new($external-id, $system-id) {
    self.parse(:$external-id, :$system-id);
}

multi method new(|c) is default { nextsame }

multi method parse(Str :$string!, xmlEncodingStr:D :$enc = 'UTF-8') {
    my xmlDtd:D $native = LibXML::Parser::Context.try: {xmlDtd.parse: :$string, :$enc};
    self.new: :$native;
}
multi method parse(Str:D :$external-id, Str:D :$system-id) {
    my xmlDtd:D $native = LibXML::Parser::Context.try: {xmlDtd.parse: :$external-id, :$system-id;};
    self.new: :$native;
}
multi method parse(Str $external-id, Str $system-id) is default {
    self.parse: :$external-id, :$system-id;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) {
    my xmlDtd:D $native = self.native.copy;
    self.clone: :$native;
}

method !valid-ctx { ValidContext.new: :schema(self) }
method validate(LibXML::Node:D $node) {
    self!valid-ctx.validate($node);
}
method is-valid(LibXML::Node:D $node) {
    self!valid-ctx.validate($node, :check);
}

multi method ACCEPTS(LibXML::Dtd:D: LibXML::Node:D $node) {
    self.is-valid($node);
}

=begin pod
=head1 NAME

LibXML::Dtd - LibXML DTD Handling

=head1 SYNOPSIS



  use LibXML::Dtd;

  my LibXML::Dtd $dtd .= new($public-id, $system-id);
  my LibXML::Dtd $dtd .= parse: :string($dtd-str);
  my Str $dtdName = $dtd.getName();
  my Str $publicId = $dtd.publicId();
  my Str $systemId = $dtd.systemId();
  try { $dtd.validate($doc) };
  my Bool $valid = $dtd.is-valid($doc);
  if $doc ~~ $dtd { ... } # if doc is valid against the DTD

=head1 DESCRIPTION

This class holds a DTD. You may parse a DTD from either a string, or from an
external SYSTEM identifier.

No support is available as yet for parsing from a filehandle.

LibXML::Dtd is a sub-class of L<<<<<< LibXML::Node >>>>>>, so all the methods available to nodes (particularly Str()) are available
to Dtd objects.


=head1 METHODS


=begin item
new

  my LibXML::Dtd $dtd  .= new: :$public-id, :$system-id;
  my LibXML::Dtd $dtd2 .= new($public-id, $system-id);

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
=end item


=begin item
parse

  my LibXML::Dtd $dtd .= parse: :string($dtd-str);

The same as new() above, except you can parse a DTD from a string. Note that
parsing from string may fail if the DTD contains external parametric-entity
references with relative URLs.
=end item


=begin item
getName

  my Str $name = $dtd.getName();

Returns the name of DTD; i.e., the name immediately following the DOCTYPE
keyword.
=end item


=begin item
publicId

  my Str $publicId = $dtd.publicId();

Returns the public identifier of the external subset.
=end item


=begin item
systemId

  my Str $systemId = $dtd.systemId();

Returns the system identifier of the external subset.
=end item

=begin item1
validate

  try { $dtd.validate( $doc ); };

This function allows one to validate a (parsed) document against the given XML
Schema. The argument of this function should be a L<<<<<< LibXML::Document >>>>>> object. If this function succeeds, it will return 0, otherwise it will die()
and report the errors found. Because of this validate() should be always
evaluated.

=end item1

=begin item1
is-valid / ACCEPTS

  my Bool $valid = $dtd.is-valid($doc);
  $valid = $doc ~~ $dtd;

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
