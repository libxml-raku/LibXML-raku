use LibXML::Node;
use LibXML::_TextNode;

unit class LibXML::Comment
    is LibXML::Node
    does LibXML::_TextNode;

use LibXML::Native;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlCommentNode:D :native($)!) { }
multi submethod TWEAK(LibXML::Node :doc($doc-obj), Str :$content!) {
    my xmlDoc:D $doc = .native with $doc-obj;
    my xmlCommentNode $comment-struct .= new: :$content, :$doc;
    self.set-native: $comment-struct;
}

method native { callsame() // xmlCommentNode }
method content is rw handles<substr substr-rw> { $.native.content };

=begin pod
=head1 NAME

LibXML::Comment - LibXML Comment Class

=head1 SYNOPSIS



  use LibXML::Comment;
  # Only methods specific to Comment nodes are listed here,
  # see the LibXML::Node manpage for other methods

  my LibXML::Comment $node .= new( :$content );

=head1 DESCRIPTION

This class provides all functions of L<<<<<< LibXML::Text >>>>>>, but for comment nodes. This can be done, since only the output of the node
types is different, but not the data structure. :-)


=head1 METHODS

The class inherits from L<<<<<< LibXML::Node >>>>>>. The documentation for Inherited methods is not listed here.

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation.

=begin item
new

  my LibXML::Comment $node .= new( :$content );

The constructor is the only provided function for this package. It is required,
because I<<<<<< libxml2 >>>>>> treats text nodes and comment nodes slightly differently.

=end item

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
