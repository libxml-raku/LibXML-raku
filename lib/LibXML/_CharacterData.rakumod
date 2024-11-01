#| This role models the W3C DOM CharacterData abstract class
unit role LibXML::_CharacterData;

use LibXML::Raw;
use LibXML::Node;

multi method new(LibXML::Node :doc($owner), Str() :$content!, *%c) {
    my xmlDoc $doc = .raw with $owner;
    my anyNode:D $raw = self.raw.new: :$content, :$doc;
    self.box: $raw, |%c;
}
multi method new(Str:D() $content, *%c) {
    self.new(:$content, |%c);
}

method data {...}
method cloneNode {...}
method length { $.data.chars }

# DOM Boot-leather
method substringData(UInt:D $off, UInt:D $len --> Str) { $.data.substr($off, $len) }
method appendData(Str:D $val --> Str) { self.appendText($val); $.data; }
method insertData(UInt:D $pos, Str:D $val) { $.data.substr-rw($pos, 0) = $val; }
method setData(Str:D $val --> Str) { $.data = $val; }
method getData returns Str { $.data }
multi method replaceData(UInt:D $off, UInt:D $length, Str:D $val --> Str) {
    my $len = $.length;
    if $len > $off {
        $.data.substr-rw($off, $length) = $val;
    }
    else {
        Str
    }
}

method splitText(UInt $off) {
    my $len = $.length;
    my $new = self.cloneNode;
    with self.parent {
        .insertAfter($new, self);
    }
    if $off >= $len {
        $new.setData('');
    }
    else {
        self.replaceData($off, $len - $off, '');
        $new.replaceData(0, $off, '');
    }
    $new;
}

my subset StrOrRegex where Str|Regex;
my subset StrOrCode where Str|Code;
method replaceDataString(StrOrRegex:D $old, StrOrCode:D $new, |c --> Str) {
    $.data .= subst($old, $new, |c);
}
method deleteDataString(StrOrRegex:D $old, |c --> Str) {
    $.replaceDataString($old, '', |c);
}
multi method replaceData(StrOrRegex:D $old, StrOrCode:D $new, |c  --> Str) {
    $.replaceDataString($old, $new, |c);
}
multi method deleteData(UInt:D $off, UInt:D $length --> Str) {
    $.replaceData($off, $length, '');
}
multi method deleteData(StrOrRegex $old, |c --> Str) {
    $.replaceData($old, '', |c);
}

=begin pod

=head2 Methods

Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation. 

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

