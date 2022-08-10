#| LibXML Text Nodes
unit class LibXML::Text;

use LibXML::Node;
use LibXML::Raw;
use LibXML::_Rawish;
use LibXML::_CharacterData;
use W3C::DOM;
use Method::Also;
use NativeCall;

also is LibXML::Node;
also does LibXML::_CharacterData;
also does LibXML::_Rawish[xmlTextNode];
also does W3C::DOM::Text;

method data is also<text content ast> is rw handles<substr substr-rw> { $.raw.content };

=begin pod

=head2 Synopsis

  use LibXML::Text;
  # Only methods specific to Text nodes are listed here,
  # see the LibXML::Node documentation for other methods

  my LibXML::Text $text .= new: :$content; 
  my Str $content = $text.data;

  # Stringy Interface
  $text.data = $text-content;
  my $substr    = $text.data.substr($offset, $length);
  $text.data   ~= $somedata ;                   # append
  $text.data.substr-rw($offset, 0) = $string;   # insert
  $text.data.substr-rw($offset, $length) = '';  # delete
  $text.data   ~~ s/$remstring//;               # delete once
  $text.data   ~~ s:g/$remstring//;             # delete all
  $text.data.substr-rw($offset, $length) = $string; # replace
  $text.data   ~~ s/(<[a..z]>)/-/;         # replace pattern
  $text.data   ~~ s:g/<[a..z]>/{$0.uc}/;   # replace pattern, all

  # DOM Interface
  $text.setData( $text-content );
  $text.substringData($offset, $length);
  $text.appendData( $somedata );
  $text.insertData($offset, $string);
  $text.deleteData($offset, $length);
  $text.deleteDataString($remstring, :g);
  $text.replaceData($offset, $length, $string);
  $text.replaceDataString($old, $new, :g);

=head2 Description

Unlike the DOM specification, LibXML implements the text node as the base class
of all character data node. Therefore there exists no CharacterData class. This
allows one to apply methods of text nodes also to Comments CDATA-sections and
Processing instruction nodes.

The DOM methods are provided for compatibility with ported Perl code.

`data` provides a proxy to a rw string, which allows for idiomatic Raku string manipulation and update.


=head2 Methods

The class inherits from L<LibXML::Node>. The documentation for Inherited methods is not listed here. 

Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation. 

=head3 method new

  method new( Str :$content ) returns LibXML::Text 
The constructor of the class. It creates an unbound text node.


=head3 method data

  method data() returns Str

Although there exists the C<nodeValue> attribute in the Node class, the DOM specification defines data as a separate
attribute. C<LibXML> implements these two attributes not as different attributes, but as aliases,
such as C<libxml2> does. Therefore

  $text.data;

and

  $text.nodeValue;

will have the same result and are not different entities.

=head3 method setData

  method setData(Str $text) returns Str

This function sets or replaces text content to a node. The node has to be of
the type "text", "cdata" or "comment".

=head3 method substringData

  method substringData(UInt $offset, UInt $length) returns Str;

Extracts a range of data from the node. (DOM Spec) This function takes the two
parameters $offset and $length and returns the sub-string, if available.

If the node contains no data or $offset refers to an non-existing string index,
this function will return I<Str:U>. If $length is out of range C<substringData> will return the data starting at $offset instead of causing an error.

=head3 method appendData

  method appendData( Str $somedata ) returns Str;

Appends a string to the end of the existing data. If the current text node
contains no data, this function has the same effect as C<setData>.

=head3 method insertData

  method insertData(UInt $offset, UInt $string) returns Str;

Inserts the parameter $string at the given $offset of the existing data of the
node. This operation will not remove existing data, but change the order of the
existing data.

If $offset is out of range, C<insertData> will have the same behaviour as C<appendData>.

=head3 method deleteData

  method deleteData(UInt $offset, UInt $length);

This method removes a chunk from the existing node data at the given offset.
The $length parameter tells, how many characters should be removed from the
string.


=head3 method deleteDataString

  method deleteDataString(Str $remstring, Bool :$g);

This method removes a chunk from the existing node data. Since the DOM spec is
quite unhandy if you already know C<which> string to remove from a text node, this method allows more Rakuish code :)

The functions takes two parameters: I<$string> and optional the I<:g> flag. If :g is not set, C<deleteDataString> will remove only the first occurrence of $string. If $g is I<True>C<deleteDataString> will remove all occurrences of I<$string> from the node data.


=head3 method replaceData

  method replaceData(UInt $offset, UInt $length, Str $string) returns Str;

The DOM style version to replace node data.


=head3 method replaceDataString

  my subset StrOrRegex where Str|Regex;
  my subset StrOrCode where Str|Code;
  method replaceDataString(StrOrRegex $old, StrOrCode $new, *%opts);

The more programmer friendly version of replaceData() :)

Instead of giving offsets and length one can specify the exact string or a regular expression (I<$old>) to be replaced. Additionally the I<:g> option allows one to replace all occurrences of I<$old>.

I<NOTE:> This is a shortcut for

  my $datastr = $node.data ~~ s/somecond/replacement/g; # 'g' is just an example for any flag

=head3 method splitText

   method splitText(UInt $offset) returns LibXML::Text

Breaks this node into two nodes at the specified offset, keeping both in the tree as siblings. After being split, this node will contain all the content up to the offset point. A new text node containing all the content at and after the offset point, is returned.

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
