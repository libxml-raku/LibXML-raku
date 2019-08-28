use LibXML::Node;
use LibXML::_TextNode;

unit class LibXML::CDATA
    is LibXML::Node
    does LibXML::_TextNode;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCDataNode:D :native($)!) { }
multi submethod TWEAK(:doc($owner), Str :$content!) {
    my xmlDoc:D $doc = .native with $owner;
    my xmlCDataNode:D $cdata-struct .= new: :$content, :$doc;
    self.set-native: $cdata-struct;
}

method native { callsame() // xmlCDataNode }
method content is rw handles<substr substr-rw> { $.native.content };

=begin pod
=head1 NAME

LibXML::CDATA - LibXML Class for CDATA Sections

=head1 SYNOPSIS



  use LibXML::CDATA;
  # Only methods specific to CDATA nodes are listed here,
  # see the LibXML::Node manpage for other methods

  my LibXML::CDATA $node .= new( :$content );

=head1 DESCRIPTION

This class provides all functions of L<<<<<< LibXML::Text >>>>>>, but for CDATA nodes.


=head1 METHODS

The class inherits from L<<<<<< LibXML::Node >>>>>>. The documentation for Inherited methods is not listed here.

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation.

=begin item
new

  my LibXML::CDATA $node .= new( :$content );

The constructor is the only provided function for this package. It is required,
because I<<<<<< libxml2 >>>>>> treats the different text node types slightly differently.

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

=cut


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
