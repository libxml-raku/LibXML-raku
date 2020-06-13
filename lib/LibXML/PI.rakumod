use LibXML::Node;

#| LibXML Processing Instructions
unit class LibXML::PI
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Raw;
use NativeCall;

method new(:doc($owner)!, Str :$name!, Str :$content!) {
    my xmlDoc:D $doc = .raw with $owner;
    my xmlPINode:D $raw .= new: :$name, :$content, :$doc;
    self.box: $raw;
}

method raw { nativecast(xmlPINode, self) }
method content is rw handles<substr substr-rw> { $.raw.content };

multi method setData(*%atts) {
    $.setData( %atts.sort.map({.key ~ '="' ~ .value ~ '"'}).join(' ') );
}
multi method setData(Str:D $string) {
    $.raw.setNodeValue($string);
}

=begin pod

=head2 Synopsis

  use LibXML::Document;
  use LibXML::PI;
  # Only methods specific to Processing Instruction nodes are listed here,
  # see the LibXML::Node documentation for other methods

  my LibXML::Document $dom .= new;
  my LibXML::PI $pi = $dom.createProcessingInstruction("abc");

  $pi.setData( $data_string );
  $pi.setData( name=>string_value [...] );

  $pi.data ~~ s/xxx/yyy/; # Stringy Interface - see LibXML::Text

=head2 Description

Processing instructions are implemented with LibXML with read and write
access. The PI data is the PI without the PI target (as specified in XML 1.0
[17]) as a string. This string can be accessed with getData as implemented in L<LibXML::Node>.

Many processing instructions have attribute like data. Therefore setData() provides,
in addition to the DOM spec, the passing of named parameters. So the code segment:

  my LibXML::PI $pi = $dom.createProcessingInstruction("abc");
  $pi.setData(foo=>'bar', foobar=>'foobar');
  $dom.appendChild( $pi );

will result the following PI in the DOM:
  =begin code :lang<xml>
  <?abc foo="bar" foobar="foobar"?>
  =end code
Which is how it is specified in the DOM specification. This three step
interface creates a temporary Raku object. This can be avoided while
using the insertProcessingInstruction() method. Instead of the three calls
described above, the call

  $dom.insertProcessingInstruction("abc",'foo="bar" foobar="foobar"');

will have the same result as above.

L<LibXML::PI>'s implementation of setData() documented below differs a bit from the standard
version as available in L<LibXML::Node>:

=head2 Methods

=head3 method setData

      multi method setData( Str $data_string ) returns Mu
      multi method setData( %params ) returns Mu

This method allows one to change the content data of a PI. Additionally to the
interface specified for DOM Level2, the method provides a named parameter
interface to set the data. This parameter list is converted into a string
before it is appended to the PI.

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
