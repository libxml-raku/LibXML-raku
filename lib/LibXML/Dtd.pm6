use LibXML::Node;

unit class LibXML::Dtd
    is LibXML::Node;

use LibXML::Native;
use LibXML::Parser::Context;

method native handles <publicId systemId> {
    nextsame;
}

multi submethod TWEAK(xmlDtd:D :native($)!) { }
multi submethod TWEAK(
    Str:D :$type!,
    LibXML::Node :doc($owner), Str:D :$name!,
    Str :$external-id, Str :$system-id, ) {
    my xmlDoc $doc = .native with $owner;
    my xmlDtd:D $dtd-struct .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.native = $dtd-struct;
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

=begin pod
=head1 NAME

LibXML::Dtd - LibXML DTD Handling

=head1 SYNOPSIS



  use LibXML;

  $dtd = LibXML::Dtd.new($public-id, $system-id);
  $dtd = LibXML::Dtd.parse: :string($dtd-str);
  my Str $dtdName = $dtd.getName();
  my Str $publicId = $dtd.publicId();
  my Str $systemId = $dtd.systemId();

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
   my $doc = LibXML.new.parse: :file("test.xml");
   $doc.validate($dtd);
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



=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas


=head1 VERSION

2.0132

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
