#| Interface to libxml2 Pull Parser
unit class LibXML::Reader;

use LibXML::ErrorHandling;
use LibXML::_Configurable;

also does LibXML::_Configurable;
also does LibXML::ErrorHandling;

=begin pod

    =head2 Synopsis

      use LibXML::Reader;

      sub dump-node($reader) {
          printf "%d %d %s %d\n", $reader.depth,
                                  $reader.nodeType,
                                  $reader.name,
                                  $reader.isEmptyElement;
      }

      my LibXML::Reader $reader .= new(file => "file.xml")
             or die "cannot read file.xml\n";
      while $reader.read {
          dump-node($reader);
      }

    or

      use LibXML::Reader;

      my LibXML::Reader $reader .= new(file => "file.xml")
             or die "cannot read file.xml\n";
      $reader.preservePattern('//table/tr');
      $reader.finish;
      print $reader.document.Str(:deep);

   =head2 Description

   This is a Raku interface to libxml2's pull-parser implementation xmlTextReader I<http://xmlsoft.org/html/libxml-xmlreader.html>. Pull-parsers (such as StAX in
   Java, or XmlReader in C#) use an iterator approach to parse XML documents. They
   are easier to program than event-based parser (SAX) and much more lightweight
   than tree-based parser (DOM), which load the complete tree into memory.

   The Reader acts as a cursor going forward on the document stream and stopping
   at each node on the way. At every point, the DOM-like methods of the Reader
   object allow one to examine the current node (name, namespace, attributes,
   etc.)

   The user's code keeps control of the progress and simply calls the C<read()> function repeatedly to progress to the next node in the document order. Other
   functions provide means for skipping complete sub-trees, or nodes until a
   specific element, etc.

   At every time, only a very limited portion of the document is kept in the
   memory, which makes the API more memory-efficient than using DOM. However, it
   is also possible to mix Reader with DOM. At every point the user may copy the
   current node (optionally expanded into a complete sub-tree) from the processed
   document to another DOM tree, or to instruct the Reader to collect sub-document
   in form of a DOM tree consisting of selected nodes.

   Reader API also supports namespaces, xml:base, entity handling, DTD,
   Schema and RelaxNG validation support

   The naming of methods compared to libxml2 and C# XmlTextReader has been changed
   slightly to match the conventions of LibXML. Some functions have been
   changed or added with respect to the C interface.

=end pod

use NativeCall;
use LibXML::Config;
use LibXML::Enums;
use LibXML::Raw;
use LibXML::Raw::TextReader;
use LibXML::Types :QName, :NCName;
use LibXML::Document;
use LibXML::Pattern;
use LibXML::RelaxNG;
use LibXML::Schema;
use LibXML::_Options;
use LibXML::Parser::Context;

has xmlTextReader $.raw;
has xmlEncodingStr $!enc;
method enc { $!enc }
has Blob $!buf;
my subset RelaxNG where LibXML::RelaxNG|Str|Any:U;
my subset Schema  where LibXML::Schema|Str|Any:U;
has RelaxNG $!RelaxNG;
has Schema  $!Schema;
has $.sax-handler is rw;
has UInt $.flags is rw = LibXML::Config.parser-flags();

also does LibXML::_Options[%LibXML::Parser::Context::Opts];

# Perl compat
multi method recover is rw {
    Proxy.new(
        FETCH => { 
            my $recover = $.get-flag($!flags, 'recover');
            $recover && $.get-flag($!flags, 'suppress-errors') ?? 2 !! $recover;
        },
        STORE => -> $, UInt() $v {
            $.set-flag($!flags, 'recover', $v >= 1);
            $.set-flag($!flags, 'suppress-errors', $v >= 2);
        }
    );
}
multi method recover($v) { $.recover = $v }

method !op(Str:D $op, |c) is hidden-from-backtrace {
    my $rv := $!raw."$op"(|c);
    self.flush-errors;
    $rv;
}

method !bool-op(Str:D $op, |c) is hidden-from-backtrace {
    my Int $rv := self!op($op, |c);
    fail X::LibXML::OpFail.new(:what<Read>, :$op)
        if $rv < 0;
    $rv > 0;
}

method !uint-op(Str:D $op, |c) is hidden-from-backtrace {
    my Int $rv := self!op($op, |c);
    fail X::LibXML::OpFail.new(:what<Read>, :$op)
        if $rv < 0;
    $rv;
}

multi trait_mod:<is>(
    Method $m where {.yada && .count <= 1},
    :$reader-raw!) {
    my $name := $m.name;
    $m.wrap: do given $m.returns {
        when Bool.isa($_) { method () is hidden-from-backtrace { self!bool-op($name) } }
        when UInt.isa($_) { method () is hidden-from-backtrace { self!uint-op($name) } }
        when .isa(NCName) { method (--> NCName) is hidden-from-backtrace { self!op($name) } }
        when .isa(QName)  { method (--> QName) is hidden-from-backtrace { self!op($name) } }
        when Str.isa($_)  { method (--> Str) is hidden-from-backtrace { self!op($name) } }
        default { die "can't handle read-op method '$name' that returns {.raku}" }
    }
}

has LibXML::Document $!document;

multi submethod TWEAK( xmlTextReader:D :$!raw! ) {
}
multi submethod TWEAK(LibXML::Document:D :DOM($!document)!,
                      RelaxNG :$!RelaxNG, Schema :$!Schema,
                     ) {
    my xmlDoc:D $doc = $!document.raw;
    $!raw .= new: :$doc;
    self!setup: :!errors;
}
method !init-flags(%opts) {
    self.set-flags($!flags, |%opts);
}
multi submethod TWEAK(Blob:D :$!buf!, UInt :$len = $!buf.bytes,
                      Str :$URI,
                      RelaxNG :$!RelaxNG, Schema :$!Schema,
                      :$!enc, *%opts) {
    self!init-flags(%opts);
    $!raw .= new: :$!buf, :$len, :$!enc, :$URI, :$!flags;
    self!setup;
}
multi submethod TWEAK(Str:D :$string!, xmlEncodingStr :$!enc = 'UTF-8', |c) {
    my $buf = $string.encode($!enc);
    self.TWEAK( :$buf, :$!enc, |c);
}
multi submethod TWEAK(UInt:D :$fd!, Str :$URI,
                      RelaxNG :$!RelaxNG, Schema :$!Schema,
                      xmlEncodingStr :$!enc, *%opts) {
    self!init-flags(%opts);
    $!raw .= new: :$fd, :$!enc, :$URI, :$!flags;
    self!setup;
}
multi submethod TWEAK(IO::Handle:D :$io!, :$URI = $io.path.path, |c) {
    $io.open(:r) unless $io.opened;
    my UInt:D $fd = $io.native-descriptor;
    self.TWEAK( :$fd, :$URI, |c );
}
multi submethod TWEAK(
    Str:D :$file!,
    RelaxNG :$!RelaxNG, Schema :$!Schema,
    xmlEncodingStr :$!enc, *%opts) {
    self!init-flags(%opts);
    $!raw .= new: :$file, :$!enc, :$!flags;
    self!setup;
}
multi submethod TWEAK(Str:D :location($file)!, |c) {
    self.TWEAK: :$file, |c;
}

=begin pod
    =head2 Constructor

    Depending on the XML source, the Reader object can be created with either of:

      my LibXML::Reader $reader .= new( file => "file.xml", ... );
      my LibXML::Reader $reader .= new( string => $xml_string, ... );
      my LibXML::Reader $reader .= new( io => $file_handle, ... );
      my LibXML::Reader $reader .= new( fd => $file_handle.native_descriptor, ... );
      my LibXML::Reader $reader .= new( DOM => $dom, ... );

    where ... are reader options described below in L<Reader options> or various parser options described in L<LibXML::Parser>. The constructor recognizes the following XML sources:

    =head3 Source specification

        =begin item1
        Str :$file

        Read XML from a local file or URL.

        =end item1

        =begin item1
        Str :$string

        Read XML from a string.

        =end item1

        =begin item1
        IO::Handle :$io

        Read XML as a Raku IO::Handle object.

        =end item1

        =begin item1
        UInt :$fd

        Read XML from a file descriptor number. Possibly faster than IO.

        =end item1

        =begin item1
        LibXML::Document :$DOM

        Use reader API to walk through a pre-parsed L<LibXML::Document>.

        =end item1


    =head3 Reader options

        =begin item1
        :$encoding

        override document encoding.

        =end item1

        =begin item1
        RelaxNG => $rng-schema

        can be used to pass either a L<LibXML::RelaxNG> object or a filename or URL of a RelaxNG schema to the constructor. The schema
        is then used to validate the document as it is processed.

        =end item1

        =begin item1
        Schema => $xsd-schema

        can be used to pass either a L<LibXML::Schema> object or a filename or URL of a W3C XSD schema to the constructor. The schema
        is then used to validate the document as it is processed.

        =end item1

        =begin item1
        ...

        the reader further supports various parser options described in L<LibXML::Parser> (specifically those labeled by /reader/). 

        =end item1
=end pod

method !setup(Bool :$errors = True) {
    my Pair $call;
    if $errors {
        $!raw.setStructuredErrorFunc: -> Pointer $ctx, xmlError:D $err {
            self.structured-error($err);
        }
    }
    with $!RelaxNG {
        when Str { $call := :setRelaxNGFile($_); }
        default  { $call := :setRelaxNGSchema(.raw) }
    }
    with $!Schema {
        when Str { $call := :setXsdFile($_); }
        default  { $call := :setXsdSchema(.raw) }
    }
    self!bool-op(.key, .value) with $call;
}

submethod DESTROY {
    self.close();
    .Free with $!raw;
}

########################################################################
=head2 Methods Controlling Parsing Progress

#| Moves the position to the next node in the stream, exposing its properties.
method read returns Bool is reader-raw {...}
=para Returns True if the node was read successfully, False if there is no more nodes
    to read, or Failure in case of error


#| Parses an attribute value into one or more Text and EntityReference nodes.
method readAttributeValue returns Bool is reader-raw {...}
=para Returns True in case of success, False if the reader was not positioned on an
    attribute node or all the attribute values have been read, or Failure in case
    of error.


#| Gets the read state of the reader.
method readState returns UInt is reader-raw {...}
=para Returns the state value, or Failure in case of
    error. The module exports constants for the Reader states,
    see STATES below.


#| The depth of the node in the tree, starts at 0 for the root node.
method depth returns UInt is reader-raw {...}


#| Skip to the node following the current one in the document order while avoiding the sub-tree if any.
method next returns Bool is reader-raw {...}
=para Returns True if the node was read successfully, False if there is
    no more nodes to read, or Failure in case of error.


#| Skip nodes following the current one in the document order until a specific element is reached.
method nextElement(NCName $local-name?, Str $URI? --> Bool) {
    self!bool-op('nextElement', $local-name, $URI);
}
=para The element's name must be equal to a given localname if
    defined, and its namespace must equal to a given nsURI if defined. Either of
    the arguments can be undefined (or omitted, in case of the latter or both).
=para Returns True if the element was found, False if there is no more nodes to read,
    or Failure in case of error.


#| Skip nodes following the current one in the document order until an element
#| matching a given compiled pattern is reached.
method nextPatternMatch(LibXML::Pattern:D $pattern --> Bool) {
    self!bool-op('nextPatternMatch', $pattern.raw);
}
=para See L<LibXML::Pattern> for information on compiled patterns. See also
    the C<matchesPattern> method.
=para Returns True if the element was found, False if there is no more nodes
    to read, or Failure in case of error.


#| Skip all nodes on the same or lower level until the first node on a higher
#| level is reached. 
method skipSiblings returns Bool is reader-raw {...}
=para In particular, if the current node occurs in an element, the
    reader stops at the end tag of the parent element, otherwise it stops at a node
    immediately following the parent node.
=para Returns True if successful, False if end of the document is reached, or Failure
    in case of error.


#| Skips to the node following the current one in the document order while
#| avoiding the sub-tree if any.
method nextSibling returns Bool is reader-raw {...}
=para Returns True if the element was found, False if there is no more nodes to read,
    or Failure in case of error.


#| Like nextElement but only processes sibling elements of the current node
#| (moving forward using nextSibling() rather than read(), internally).
method nextSiblingElement(QName $name?, Str $URI?) {
    self!bool-op('nextSiblingElement', $name, $URI);
}
=para Returns True if the element was found, False if there is no more nodes to read,
      or Failure in case of error.


#| Skip all remaining nodes in the document, reaching end of the document.
method finish(--> Bool) {
    my $rv := self!bool-op('finish');
    $!buf = Nil;
    $rv;
}
=para Returns True if successful, False in case of error.


#| This method releases any resources allocated by the current instance and closes
#|  underlying input.
method close(--> Bool) {
    my $rv := ! self!bool-op('close');
    $!buf = Nil;
    $rv;
}
=para It returns False on failure and True on success. This method is
      automatically called by the destructor when the reader is forgotten, therefore
      you do not have to call it directly.

########################################################################
=head2 Methods Extracting Information

#| Returns the name of the current node.
method name returns Str is reader-raw {...}
=para Returns:
=item an element or attribute name of the form [prefix:][name], or
=item a special-name begining with '#', such as `#text`, `#comment`, or `#cdata-section`.

#| Returns the type of the current node.
method nodeType returns UInt is reader-raw {...}
=para See NODE TYPES below.


#| Returns the local name of the node.
method localName returns Str is reader-raw {...}
=para Either an element or attribute name of the form [prefix:][name], or
    a special-name begining with '#', such as `#text`, `#comment`, or `#cdata-section`.

#| Returns the prefix of the namespace associated with the node.
method prefix returns NCName is reader-raw {...}


#| Returns the URI defining the namespace associated with the node.
method namespaceURI returns Str is reader-raw {...}


#| Check if the current node is empty.
method isEmptyElement returns Bool is reader-raw {...}
=para This is a bit bizarre in the sense that
    <a/> will be considered empty while <a></a> will not.


#| Returns True if the node can have a text value.
method hasValue returns Bool is reader-raw {...}


#| Provides the text value of the node if present or Str:U if not available.
method value returns Str is reader-raw {...}

#| Reads the contents of the current node, including child nodes and markup.
method readInnerXml returns Str is reader-raw {...}
=para Returns a string containing the XML of the node's content, or Str:U if the
    current node is neither an element nor attribute, or has no child nodes.


#| Reads the contents of the current node, including child nodes and markup.
method readOuterXml returns Str is reader-raw {...}
=para Returns a string containing the XML of the node including its content, or undef
    if the current node is neither an element nor attribute.

#| Returns a canonical location path to the current element from the root node to
#|the current node.
method nodePath {
    .GetNodePath with $!raw.currentNode;
}
=item Namespaced elements are matched by '*', because there is no
    way to declare prefixes within XPath patterns.
=item Unlike C<LibXML::Node::nodePath()>, this function does not provide
    sibling counts (i.e. instead of e.g. '/a/b[1]'
    and '/a/b[2]' you get '/a/b' for both matches). 


#| Returns a true value if the current node matches a compiled pattern.
method matchesPattern(LibXML::Pattern:D $pattern --> Bool) {
    ? $pattern.matchesNode($_) with $!raw.currentNode;
}
=item  See L<LibXML::Pattern> for information on compiled patterns.
=item See also the C<nextPatternMatch> method.

########################################################################
=head2 Methods Extracting DOM Nodes

#| Provides access to the document tree built by the reader.
method document {
    $!document //= LibXML::Document.new: :raw($_)
        with $!raw.currentDoc;
}
=item This function can be
used to collect the preserved nodes (see C<preserveNode()> and preservePattern).
=item CAUTION: Never use this function to modify the tree unless reading of the whole
    document is completed!

#| This function is similar a DOM function copyNode(). It returns a copy of the currently processed node as a corresponding DOM object.
method copyCurrentNode(Bool :$deep --> LibXML::Node) {
    my $call := $deep ?? 'currentNodeTree' !! 'currentNode';
    my anyNode $node = self!op($call);
    $node .= copy: :$deep;
    &?ROUTINE.returns.box($node);
}
=item Use :deep to obtain the full sub-tree.

#| This tells the XML Reader to preserve the current node in the document tree.
method preserveNode(--> LibXML::Node) {
    $.document; # realise containing document
    &?ROUTINE.returns.box: self!op('preserveNode');
}
=para A document tree consisting of the preserved nodes and their content can be
    obtained using the method C<document()> once parsing is finished.
=para Returns the node or LibXML::Node:U in case of error.


#| This tells the XML Reader to preserve all nodes matched by the pattern (which
#| is a streaming XPath subset).
method preservePattern(Str:D $pattern, :%ns --> UInt) {
    $.document; # realise containing document
    my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
    self!uint-op('preservePattern', $pattern, $ns);
}
=begin pod
    =para
    A document tree consisting of the preserved nodes
    and their content can be obtained using the method C<document()> once parsing is finished.

    An :%ns may be used to pass a mapping
    prefixes used by the XPath to namespace URIs.

    The XPath subset available with this function is described at L<http://www.w3.org/TR/xmlschema-1/#Selector>
    and matches the production
        =begin code :lang<bnf>
        Path ::= ('.//')? ( Step '/' )* ( Step | '@' NameTest )
        =end code
    Returns a positive number in case of success or Failure in case of error
=end pod

########################################################################
=head2 Methods Processing Attributes

#| Provides the number of attributes of the current node.
method attributeCount returns UInt is reader-raw {...}

#| Whether the node has attributes.
method hasAttributes returns Bool is reader-raw {...}

#| Provides the value of the attribute with the specified qualified name.
method getAttribute(QName $name --> Str) {
    self!op: 'getAttribute', $name;
}
=para Returns a string containing the value of the specified attribute, or Str:U in
    case of error.

#| Provides the value of the specified attribute in a given namespace
method getAttributeNs(NCName $local-name, Str $namespace-URI --> Str) {
    self!op: 'getAttributeNs', $local-name, $namespace-URI;
}

#| Provides the value of the attribute with the specified index relative to the
#| containing element.
method getAttributeNo(UInt $i --> Str) {
    self!op: 'getAttributeNo', $i;
}

#| Returns True if the current attribute node was generated from the default value
#| defined in the DTD.
method isDefault returns Bool is reader-raw {...}

#| Moves the position to the attribute with the specified name
method moveToAttribute(QName $name) returns Bool {
    self!bool-op: 'moveToAttribute', $name; 
}
=para Returns True in case of success, Failure in case of error, False if not found

#| Moves the position to the attribute with the specified index relative to the
#| containing element.
method moveToAttributeNo(Int $i) returns Bool {
    self!bool-op: 'moveToAttributeNo', $i; 
}
=para Returns True in case of success, Failure in case of error, False if not found

#| Moves the position to the attribute with the specified local name and namespace URI.
method moveToAttributeNs(QName:D $name, Str $URI) {
    $URI
    ?? self!bool-op('moveToAttributeNs', $name, $URI)
    !! self!bool-op('moveToAttribute', $name );
}
=para Returns True in case of success, Failure in case of error, False if not found

#| Moves the position to the first attribute associated with the current node.
method moveToFirstAttribute returns Bool is reader-raw {...}
=para Returns True in case of success, Failure in case of error, False if not found

#| Moves the position to the next attribute associated with the current node.
method moveToNextAttribute returns Bool is reader-raw {...}
=para Returns True in case of success, Failure in case of error, False if not found

#| Moves the position to the node that contains the current attribute node.
method moveToElement returns Bool is reader-raw {...}
=para Returns True in case of success, Failure in case of error, False if not moved

#| Determine whether the current node is a namespace declaration rather than a
#| regular attribute.
method isNamespaceDecl returns Bool is reader-raw {...}
=para Returns True if the current node is a namespace declaration, False if it is a regular
    attribute or other type of node, or Failure in case of error.

########################################################################
=head2 Other Methods

#| Resolves a namespace prefix in the scope of the current element.
method lookupNamespace(Str $URI) returns NCName {
    self!op('lookupNamespace', $URI);
}
=para Returns a string containing the namespace URI to which the prefix maps or undef
    in case of error.


#| Get the encoding of the document being read
method encoding returns xmlEncodingStr { $.raw.encoding }
=para Returns a string containing the encoding of the document or Str:U in case of error.

#| Determine the standalone status of the document being read. 
method standalone returns Int {
    self!op: 'standalone';
}
=begin pod

    use LibXML::Document :XmlStandalone;
    if $reader.standalone == XmlStandaloneYes { ... }

    =para Gets or sets the Numerical value of a documents XML declarations
    standalone attribute.

    It returns
    =item I<1 (XmlStandaloneYes)> if standalone="yes" was found,
    =item I<0 (XmlStandaloneNo)> if standalone="no" was found and
    =item I<-1 (XmlStandaloneMu)> if standalone was not specified (default on creation).
=end pod


#| Determine the XML version of the document being read
method xmlVersion returns Version {
        Version.new: self!op: 'xmlVersion';
}


#| Returns the base URI of the current node.
method baseURI returns Str is reader-raw {...}


#| Retrieve the validity status from the parser.
method isValid returns Bool is reader-raw {...}
=para Returns True if valid, False if no, and Failure in case of error.

#| The xml:lang scope within which the current node resides.
method xmlLang returns Str is reader-raw {...}


#| Provide the line number of the current parsing point.
method lineNumber returns UInt is reader-raw {...}


#| Provide the column number of the current parsing point.
method columnNumber returns UInt is reader-raw {...}

#| This function provides the current index of the parser relative to the start of
#| the current entity.
method byteConsumed returns UInt is reader-raw {...}
=para This function is computed in bytes from the beginning
    starting at zero and finishing at the size in bytes of the file if parsing a
    file. The function is of constant cost if the input is UTF-8 but can be costly
    if run on non-UTF-8 input.

constant %ParserProp = %(
    :complete-attributes(XML_PARSER_DEFAULTATTRS),
    :expand-entities(XML_PARSER_SUBST_ENTITIES),
    :load-ext-entity(XML_PARSER_LOADDTD),
    :validation(XML_PARSER_VALIDATE),
);

#| Change the parser processing behaviour by changing some of its internal
#| properties.
method setParserProp( *%props --> Hash) {
    for %props.sort {
        my $prop = %ParserProp{.key} // fail "Unknown parser property: {.key}";
        $!raw.setParserProp($prop, +.value);
        self.set-flag($!flags, .key, $!raw.getParserProp($prop));
    }
    %props;
}

=para The following properties are available with this function:
    `load-ext-dtd`, `complete-attributes`, `validation`, `expand-entities`

=para Since some of the properties can only be changed before any read has been done,
    it is best to set the parsing properties at the constructor.

=para Returns True if the call was successful, or Failure in case of error


#| Get value of an parser internal property.
multi method getParserProp(Str:D $opt --> Bool) {
    my UInt $prop = %ParserProp{$opt} // fail "Unknown parser property: $opt";

    self!bool-op: 'getParserProp', $prop;
}
=para The following property names can be
    used: `load-ext-dtd`, `complete-attributes`, `validation`,
    `expand-entities`.

=para Returns the value, usually True, False, or Failure in case of error.

multi method getParserProp(Numeric:D $prop) {
    self!bool-op: 'getParserProp', $prop;
}

#| Ensure libxml2 has been compiled with the reader pull-parser enabled
method have-reader {
    ? xml6_config_have_libxml_reader();
}

method FALLBACK($key, |c) is rw {
    $.option-exists($key)
    ?? $.option($key, |c)
    !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
}

=begin pod

=head2 Destruction

LibXML takes care of the reader object destruction when the last reference to
the reader object goes out of scope. The document tree is preserved, though, if
either of $reader.document or $reader.preserveNode was used and references to
the document tree exist.


=head2 Node Types

The reader interface provides the following constants for node types (the
constant symbols are exported by default or if tag C<:types> is used).

  XML_READER_TYPE_NONE                    => 0
  XML_READER_TYPE_ELEMENT                 => 1
  XML_READER_TYPE_ATTRIBUTE               => 2
  XML_READER_TYPE_TEXT                    => 3
  XML_READER_TYPE_CDATA                   => 4
  XML_READER_TYPE_ENTITY_REFERENCE        => 5
  XML_READER_TYPE_ENTITY                  => 6
  XML_READER_TYPE_PROCESSING_INSTRUCTION  => 7
  XML_READER_TYPE_COMMENT                 => 8
  XML_READER_TYPE_DOCUMENT                => 9
  XML_READER_TYPE_DOCUMENT_TYPE           => 10
  XML_READER_TYPE_DOCUMENT_FRAGMENT       => 11
  XML_READER_TYPE_NOTATION                => 12
  XML_READER_TYPE_WHITESPACE              => 13
  XML_READER_TYPE_SIGNIFICANT_WHITESPACE  => 14
  XML_READER_TYPE_END_ELEMENT             => 15
  XML_READER_TYPE_END_ENTITY              => 16
  XML_READER_TYPE_XML_DECLARATION         => 17

=head2 States

The following constants represent the values returned by C<readState()>. They are exported by default, or if tag C<:states> is used:

  XML_READER_NONE      => -1
  XML_READER_START     =>  0
  XML_READER_ELEMENT   =>  1
  XML_READER_END       =>  2
  XML_READER_EMPTY     =>  3
  XML_READER_BACKTRACK =>  4
  XML_READER_DONE      =>  5
  XML_READER_ERROR     =>  6

=head2 SEE ALSO

L<LibXML::Pattern> for information about compiled patterns.

L<http://xmlsoft.org/html/libxml-xmlreader.html>

L<http://dotgnu.org/pnetlib-doc/System/Xml/XmlTextReader.html>


=head2 Original Perl Implementation

Heiko Klein, <H.Klein@gmx.net> and Petr Pajas

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
