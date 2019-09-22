use LibXML::Node;
use LibXML::_StringyNode;

unit class LibXML::Text
    is LibXML::Node
    does LibXML::_StringyNode;

use LibXML::Native;
use Method::Also;

multi submethod TWEAK(LibXML::Node :doc($)!, xmlTextNode:D :native($)!) { }
multi submethod TWEAK(LibXML::Node :doc($owner), Str() :$content!) {
    my xmlDoc $doc = .native with $owner;
    my xmlTextNode $text-struct .= new: :$content, :$doc;
    self.set-native($text-struct);
}

method native { callsame() // xmlTextNode }

method content is rw is also<text> handles<substr substr-rw> { $.native.content };

=begin pod
=head1 NAME

LibXML::Text - LibXML Class for Text Nodes

=head1 SYNOPSIS



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

=head1 DESCRIPTION

Unlike the DOM specification, LibXML implements the text node as the base class
of all character data node. Therefore there exists no CharacterData class. This
allows one to apply methods of text nodes also to Comments CDATA-sections and
Processing instruction nodes.

The DOM methods are provided for compatibility with ported Perl 5 code.

`data` provides a proxy to a rw string, which allows for idiomatic Perl 6 string manipulation and update.


=head1 METHODS

The class inherits from L<<<<<< LibXML::Node >>>>>>. The documentation for Inherited methods is not listed here. 

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation. 

=begin item1
new

  $text = LibXML::Text.new( $content ); 

The constructor of the class. It creates an unbound text node.

=end item1

=begin item1
data

  $nodedata = $text.data;

Although there exists the C<<<<<< nodeValue >>>>>> attribute in the Node class, the DOM specification defines data as a separate
attribute. C<<<<<< LibXML >>>>>> implements these two attributes not as different attributes, but as aliases,
such as C<<<<<< libxml2 >>>>>> does. Therefore



  $text.data;

and



  $text.nodeValue;

will have the same result and are not different entities.

=end item1


=begin item1
setData($string)

  $text.setData( $text-content );

This function sets or replaces text content to a node. The node has to be of
the type "text", "cdata" or "comment".

=end item1

=begin item1
substringData($offset,$length)

  $text.substringData($offset, $length);

Extracts a range of data from the node. (DOM Spec) This function takes the two
parameters $offset and $length and returns the sub-string, if available.

If the node contains no data or $offset refers to an non-existing string index,
this function will return I<<<<<< Str:U >>>>>>. If $length is out of range C<<<<<< substringData >>>>>> will return the data starting at $offset instead of causing an error.

=end item1

=begin item1
appendData($string)

  $text.appendData( $somedata );

Appends a string to the end of the existing data. If the current text node
contains no data, this function has the same effect as C<<<<<< setData >>>>>>.

=end item1

=begin item1
insertData($offset,$string)

  $text.insertData($offset, $string);

Inserts the parameter $string at the given $offset of the existing data of the
node. This operation will not remove existing data, but change the order of the
existing data.

The $offset has to be a positive value. If $offset is out of range, C<<<<<< insertData >>>>>> will have the same behaviour as C<<<<<< appendData >>>>>>.

=end item1

=begin item1
deleteData($offset, $length)

  $text.deleteData($offset, $length);

This method removes a chunk from the existing node data at the given offset.
The $length parameter tells, how many characters should be removed from the
string.

=end item1

=begin item1
deleteDataString($string, :g)

  $text.deleteDataString($remstring, :g);

This method removes a chunk from the existing node data. Since the DOM spec is
quite unhandy if you already know C<<<<<< which >>>>>> string to remove from a text node, this method allows more perlish code :)

The functions takes two parameters: I<<<<<< $string >>>>>> and optional the I<<<<<< :g >>>>>> flag. If :g is not set, C<<<<<< deleteDataString >>>>>> will remove only the first occurrence of $string. If $all is I<<<<<< TRUE >>>>>>C<<<<<< deleteDataString >>>>>> will remove all occurrences of I<<<<<< $string >>>>>> from the node data.

=end item1

=begin item1
replaceData($offset, $length, $string)

  $text.replaceData($offset, $length, $string);

The DOM style version to replace node data.

=end item1

=begin item1
replaceDataString($oldstring, $newstring, [$all])

  $text.replaceDataString($old, $new, $flag);

The more programmer friendly version of replaceData() :)

Instead of giving offsets and length one can specify the exact string (I<<<<<< $oldstring >>>>>>) to be replaced. Additionally the I<<<<<< $all >>>>>> flag allows one to replace all occurrences of I<<<<<< $oldstring >>>>>>.

=end item1

=begin item1
replaceDataRegEx( $search-cond, $replace-cond, $reflags )

  $text.replaceDataRegEx( $search-cond, $replace-cond, $reflags );

This method replaces the node's data by a C<<<<<< simple >>>>>> regular expression. Optional, this function allows one to pass some flags that
will be added as flag to the replace statement.

I<<<<<< NOTE: >>>>>> This is a shortcut for



  my $datastr = $node.getData();
   $datastr =~ s/somecond/replacement/g; # 'g' is just an example for any flag
   $node.setData( $datastr );

This function can make things easier to read for simple replacements. For more
complex variants it is recommended to use the code snippet above.

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
