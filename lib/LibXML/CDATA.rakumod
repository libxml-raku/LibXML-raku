use LibXML::Node;
use LibXML::_StringyNode;
use DOM;

#| LibXML CDATA Section nodes
unit class LibXML::CDATA
    is repr('CPointer')
    is LibXML::Node
    does LibXML::_StringyNode
    does DOM::CDATASection;

use LibXML::Raw;
use NativeCall;
method raw { nativecast(xmlCDataNode, self) }
method content is rw handles<substr substr-rw> { $.raw.content };
method splitText { die X::NYI.new }

=begin pod
=head2 Synopsis

  use LibXML::CDATA;
  # Only methods specific to CDATA nodes are listed here,
  # see the LibXML::Node documentation for other methods

  my LibXML::CDATA $cdata .= new( :$content );

  $cdata.data ~~ s/xxx/yyy/; # Stringy Interface - see LibXML::Text

=head2 Description

This class provides all functions of L<LibXML::Text>, but for CDATA nodes.

=head2 Methods

The class inherits from L<LibXML::Node>. The documentation for Inherited methods is not listed here.

Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation.

=head3 method new

  method new( Str :$content ) returns LibXML::CDATA

The constructor is the only provided function for this package. It is required,
because I<libxml2> treats the different text node types slightly differently.

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
