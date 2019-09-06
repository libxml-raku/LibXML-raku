use v6;

class X::LibXML::Reader::OpFail is Exception {
    has Str:D $.op is required;
    method message { "XML Read $!op operation failed" }
}

class LibXML::Reader {

    use NativeCall;
    use LibXML::Enums;
    use LibXML::ErrorHandler;
    use LibXML::Native;
    use LibXML::Native::TextReader;
    use LibXML::Types :QName;
    use LibXML::Document;
    use LibXML::Pattern;
    use LibXML::RelaxNG;
    use LibXML::Schema;
    use LibXML::_Options;
    use  LibXML::Parser::Context;

    has xmlTextReader $.native handles<
        attributeCount baseURI byteConsumed columnNumber depth
        encoding getAttribute getAttributeNo getAttributeNs
        lineNumber localName lookupNamespace name namespaceURI
        nodeType prefix readAttributeValue readInnerXml readOuterXml
        value readState standalone xmlLang xmlVersion
    >;
    has xmlEncodingStr $!enc;
    method enc { $!enc }
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;
    has Blob $!buf;
    my subset RelaxNG where {!.defined || $_ ~~ LibXML::RelaxNG|Str};
    my subset Schema  where {!.defined || $_ ~~ LibXML::Schema|Str};
    has RelaxNG $!RelaxNG;
    has Schema  $!Schema;

    # Perl 5 compat
    also does LibXML::_Options[%LibXML::Parser::Context::Opts];

    multi method recover is rw {
        Proxy.new(
            FETCH => { 
                my $recover = $.get-flag($!flags, 'recover');
                $recover && $.get-flag($!flags, 'suppress-errors') ?? 2 !! $recover;
            },
            STORE => -> $, UInt() $v {
                $!errors.recover = $v >= 1;
                $.set-flag($!flags, 'recover', $v >= 1);
                $.set-flag($!flags, 'suppress-errors', $v >= 2);
            }
        );
    }
    multi method recover($v) { $.recover = $v }

    method !try(Str:D $op, |c) {
        my $rv := $!native."$op"(|c);
        self.flush-errors;
        $rv;
    }

    method !try-bool(Str:D $op, |c) {
        my $rv := self!try($op, |c);
        fail X::LibXML::Reader::OpFail.new(:$op)
            if $rv < 0;
        $rv > 0;
    }

    INIT {
        for <
            hasAttributes hasValue isDefault isEmptyElement isNamespaceDecl isValid
            moveToAttribute moveToAttributeNo moveToElement moveToFirstAttribute moveToNextAttribute next
            nextSibling read skipSiblings
         > {
            $?CLASS.^add_method( $_, method (|c) { self!try-bool($_, |c) });
        }

    }

    has UInt $.flags is rw = 0;
    has LibXML::Document $!document;
    method document {
        $!document //= LibXML::Document.new: :native($_)
            with $!native.currentDoc;
    }

    multi submethod TWEAK( xmlTextReader:D :$!native! ) {
    }
    multi submethod TWEAK(LibXML::Document:D :DOM($!document)!,
                          RelaxNG :$!RelaxNG, Schema :$!Schema,
                         ) {
        my xmlDoc:D $doc = $!document.native;
        $!native .= new: :$doc;
        self!setup: :!errors;
    }
    method !init-flags(%opts) {
        self.set-flags($!flags, :expand-entities, |%opts);
    }
    multi submethod TWEAK(Blob:D :$!buf!, UInt :$len = $!buf.bytes,
                          Str :$URI, RelaxNG :$!RelaxNG, Schema :$!Schema,
                          :$!enc, *%opts) {
        self!init-flags(%opts);
        $!native .= new: :$!buf, :$len, :$!enc, :$URI, :$!flags;
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
        $!native .= new: :$fd, :$!enc, :$URI, :$!flags;
        self!setup;
    }
    multi submethod TWEAK(IO::Handle:D :$io!, :$URI = $io.path.path, |c) {
        $io.open(:r) unless $io.opened;
        my UInt:D $fd = $io.native-descriptor;
        self.TWEAK( :$fd, :$URI, |c );
    }
    multi submethod TWEAK(Str:D :$URI!, |c) {
        my IO::Handle:D $io = $URI.IO.open(:r);
        my UInt:D $fd = $io.native-descriptor;
        self.TWEAK: :$fd, :$URI, |c;
    }
    multi submethod TWEAK(Str:D :location($URI)!, |c) {
        self.TWEAK: :$URI, |c;
    }

    method !setup(Bool :$errors = True) {
        my Pair $call;
        if $errors {
            $!native.setStructuredErrorFunc: -> Pointer $ctx, xmlError:D $err {
                self.structured-error($err);
            }
        }
        with $!RelaxNG {
            when Str { $call := :setRelaxNGFile($_); }
            default  { $call := :setRelaxNGSchema(.native) }
        }
        with $!Schema {
            when Str { $call := :setXsdFile($_); }
            default  { $call := :setXsdSchema(.native) }
        }
        self!try-bool(.key, .value) with $call;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    method copyCurrentNode(Bool :$deep) {
        my $call := $deep ?? 'currentNodeTree' !! 'currentNode';
        my anyNode $node = self!try($call);
        $node .= copy: :$deep;
        LibXML::Node.box($node);
    }

    multi method getParserProp(Str:D $opt) {
        my UInt $flag = %(
                    :complete-attributes(XML_PARSER_DEFAULTATTRS),
                    :expand-entities(XML_PARSER_SUBST_ENTITIES),
                    :load-ext-entity(XML_PARSER_LOADDTD),
                    :validation(XML_PARSER_VALIDATE),
                ){$opt.lc.subst('_', '-', :g)} // fail "Unknown parser property: $opt";
                    
        $!native.getParserProp: $flag;
    }

    multi method getParserProp(Numeric:D $opt) {
        $!native.getParserProp: $opt;
    }

    method moveToAttributeNs(QName:D $name, Str $URI) {
        $URI
        ?? self!try-bool('moveToAttributeNs', $name, $URI)
        !! self!try-bool('moveToAttribute', $name );
    }

    method nextElement(QName $name?, Str $URI?) {
        self!try-bool('nextElement', $name, $URI);
    }

    method nextPatternMatch(LibXML::Pattern:D $pattern) {
        self!try-bool('nextPatternMatch', $pattern.native);
    }

    method nextSiblingElement(QName $name?, Str $URI?) {
        self!try-bool('nextSiblingElement', $name, $URI);
    }

    method preservePattern(Str:D $pattern, :%ns) {
        $.document; # realise containing document
        my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
        self!try('preservePattern', $pattern, $ns);
    }

    method matchesPattern(LibXML::Pattern:D $pattern) {
        $pattern.matchesNode($_) with $!native.currentNode;
    }

    method nodePath {
        .GetNodePath with $!native.currentNode;
    }

    method preserveNode(Bool :$deep) {
        $.document; # realise containing document
        my anyNode $node = self!try('preserveNode');
        LibXML::Node.box($node);
    }

    method close(--> Bool) {
        my $rv := ! self!try-bool('close');
        $!buf = Nil;
        $rv;
    }

    method finish(--> Bool) {
        my $rv := self!try-bool('finish');
        $!buf = Nil;
        $rv;
    }

    method have-reader {
        ? xml6_gbl_have_libxml_reader();
    }

    method FALLBACK($key, |c) is rw {
        $.option-exists($key)
        ?? $.option($key, |c)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }

}

=begin pod
=head1 NAME

LibXML::Reader - LibXML::Reader - interface to libxml2 pull parser

=head1 SYNOPSIS



  use LibXML::Reader;



  my $reader = LibXML::Reader.new(location => "file.xml")
         or die "cannot read file.xml\n";
  while ($reader.read) {
    processNode($reader);
  }



  sub processNode($reader) {
      printf "%d %d %s %d\n", ($reader.depth,
                               $reader.nodeType,
                               $reader.name,
                               $reader.isEmptyElement);
  }

or



  my $reader = LibXML::Reader.new(location => "file.xml")
         or die "cannot read file.xml\n";
    $reader.preservePattern('//table/tr');
    $reader.finish;
    print $reader.document.Str(:deep);


=head1 DESCRIPTION

This is a perl interface to libxml2's pull-parser implementation xmlTextReader I<<<<<< http://xmlsoft.org/html/libxml-xmlreader.html >>>>>>. This feature requires at least libxml2-2.6.21. Pull-parsers (such as StAX in
Java, or XmlReader in C#) use an iterator approach to parse XML documents. They
are easier to program than event-based parser (SAX) and much more lightweight
than tree-based parser (DOM), which load the complete tree into memory.

The Reader acts as a cursor going forward on the document stream and stopping
at each node on the way. At every point, the DOM-like methods of the Reader
object allow one to examine the current node (name, namespace, attributes,
etc.)

The user's code keeps control of the progress and simply calls the C<<<<<< read() >>>>>> function repeatedly to progress to the next node in the document order. Other
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


=head1 CONSTRUCTOR

Depending on the XML source, the Reader object can be created with either of:



    my LibXML::Reader $reader .= new( location => "file.xml", ... );
    my LibXML::Reader $reader .= new( string => $xml_string, ... );
    my LibXML::Reader $reader .= new( io => $file_handle, ... );
    my LibXML::Reader $reader .= new( fd => $file_handle.native_descriptor, ... );
    my LibXML::Reader $reader .= new( DOM => $dom, ... );

where ... are (optional) reader options described below in L<<<<<< Reader options >>>>>> or various parser options described in L<<<<<< LibXML::Parser >>>>>>. The constructor recognizes the following XML sources:


=head2 Source specification

=begin item1
location

Read XML from a local file or URL.

=end item1

=begin item1
string

Read XML from a string.

=end item1

=begin item1
IO

Read XML a Perl IO filehandle.

=end item1

=begin item1
FD

Read XML from a file descriptor (bypasses Perl I/O layer, only applicable to
filehandles for regular files or pipes). Possibly faster than IO.

=end item1

=begin item1
DOM

Use reader API to walk through a pre-parsed L<<<<<< LibXML::Document >>>>>>.

=end item1


=head2 Reader options

=begin item1
:$encoding

override document encoding.

=end item1

=begin item1
RelaxNG => $rng-schema

can be used to pass either a L<<<<<< LibXML::RelaxNG >>>>>> object or a filename or URL of a RelaxNG schema to the constructor. The schema
is then used to validate the document as it is processed.

=end item1

=begin item1
Schema => $xsd-schema

can be used to pass either a L<<<<<< LibXML::Schema >>>>>> object or a filename or URL of a W3C XSD schema to the constructor. The schema
is then used to validate the document as it is processed.

=end item1

=begin item1
...

the reader further supports various parser options described in L<<<<<< LibXML::Parser >>>>>> (specifically those labeled by /reader/). 

=end item1


=head1 METHODS CONTROLLING PARSING PROGRESS

=begin item1
read()

Moves the position to the next node in the stream, exposing its properties.

Returns 1 if the node was read successfully, 0 if there is no more nodes to
read, or -1 in case of error

=end item1

=begin item1
readAttributeValue()

Parses an attribute value into one or more Text and EntityReference nodes.

Returns 1 in case of success, 0 if the reader was not positioned on an
attribute node or all the attribute values have been read, or -1 in case of
error.

=end item1

=begin item1
readState()

Gets the read state of the reader. Returns the state value, or -1 in case of
error. The module exports constants for the Reader states, see STATES below.

=end item1

=begin item1
depth()

The depth of the node in the tree, starts at 0 for the root node.

=end item1

=begin item1
next()

Skip to the node following the current one in the document order while avoiding
the sub-tree if any. Returns True if the node was read successfully, False if there is
no more nodes to read, or Failure in case of error.

=end item1

=begin item1
nextElement(localname?,nsURI?)

Skip nodes following the current one in the document order until a specific
element is reached. The element's name must be equal to a given localname if
defined, and its namespace must equal to a given nsURI if defined. Either of
the arguments can be undefined (or omitted, in case of the latter or both).

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

=end item1

=begin item1
nextPatternMatch(compiled_pattern)

Skip nodes following the current one in the document order until an element
matching a given compiled pattern is reached. See L<<<<<< LibXML::Pattern >>>>>> for information on compiled patterns. See also the C<<<<<< matchesPattern >>>>>> method.

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

=end item1

=begin item1
skipSiblings()

Skip all nodes on the same or lower level until the first node on a higher
level is reached. In particular, if the current node occurs in an element, the
reader stops at the end tag of the parent element, otherwise it stops at a node
immediately following the parent node.

Returns True if successful, False if end of the document is reached, or Failure in case of
error.

=end item1

=begin item1
nextSibling()

It skips to the node following the current one in the document order while
avoiding the sub-tree if any.

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

=end item1

=begin item1
nextSiblingElement (name?,nsURI?)

Like nextElement but only processes sibling elements of the current node
(moving forward using C<<<<<< nextSibling() >>>>>> rather than C<<<<<< read() >>>>>>, internally).

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

=end item1

=begin item1
finish()

Skip all remaining nodes in the document, reaching end of the document.

Returns True if successful, False in case of error.

=end item1

=begin item1
close()

This method releases any resources allocated by the current instance and closes
any underlying input. It returns False on failure and True on success. This method is
automatically called by the destructor when the reader is forgotten, therefore
you do not have to call it directly.

=end item1


=head1 METHODS EXTRACTING INFORMATION

=begin item1
name()

Returns the qualified name of the current node, equal to (Prefix:)LocalName.

=end item1

=begin item1
nodeType()

Returns the type of the current node. See NODE TYPES below.

=end item1

=begin item1
localName()

Returns the local name of the node.

=end item1

=begin item1
prefix()

Returns the prefix of the namespace associated with the node.

=end item1

=begin item1
namespaceURI()

Returns the URI defining the namespace associated with the node.

=end item1

=begin item1
isEmptyElement()

Check if the current node is empty, this is a bit bizarre in the sense that
<a/> will be considered empty while <a></a> will not.

=end item1

=begin item1
hasValue()

Returns true if the node can have a text value.

=end item1

=begin item1
value()

Provides the text value of the node if present or undef if not available.

=end item1

=begin item1
readInnerXml()

Reads the contents of the current node, including child nodes and markup.
Returns a string containing the XML of the node's content, or undef if the
current node is neither an element nor attribute, or has no child nodes.

=end item1

=begin item1
readOuterXml()

Reads the contents of the current node, including child nodes and markup.

Returns a string containing the XML of the node including its content, or undef
if the current node is neither an element nor attribute.

=end item1

=begin item1
nodePath()

Returns a canonical location path to the current element from the root node to
the current node. Namespaced elements are matched by '*', because there is no
way to declare prefixes within XPath patterns. Unlike C<<<<<< LibXML::Node::nodePath() >>>>>>, this function does not provide sibling counts (i.e. instead of e.g. '/a/b[1]'
and '/a/b[2]' you get '/a/b' for both matches). 

=end item1

=begin item1
matchesPattern($compiled-pattern)

Returns a true value if the current node matches a compiled pattern. See L<<<<<< LibXML::Pattern >>>>>> for information on compiled patterns. See also the C<<<<<< nextPatternMatch >>>>>> method.

=end item1


=head1 METHODS EXTRACTING DOM NODES

=begin item1
document()

Provides access to the document tree built by the reader. This function can be
used to collect the preserved nodes (see C<<<<<< preserveNode() >>>>>> and preservePattern).

CAUTION: Never use this function to modify the tree unless reading of the whole
document is completed!

=end item1

=begin item1
copyCurrentNode(:$deep)

This function is similar a DOM function C<<<<<< copyNode() >>>>>>. It returns a copy of the currently processed node as a corresponding DOM
object. Use :deep to obtain the full sub-tree.

=end item1

=begin item1
preserveNode()

This tells the XML Reader to preserve the current node in the document tree. A
document tree consisting of the preserved nodes and their content can be
obtained using the method C<<<<<< document() >>>>>> once parsing is finished.

Returns the node or NULL in case of error.

=end item1

=begin item1
preservePattern($pattern, :%ns)

This tells the XML Reader to preserve all nodes matched by the pattern (which
is a streaming XPath subset). A document tree consisting of the preserved nodes
and their content can be obtained using the method C<<<<<< document() >>>>>> once parsing is finished.

An :%ns may be used to pass a reference mapping
prefixes used by the XPath to namespace URIs.

The XPath subset available with this function is described at



  http://www.w3.org/TR/xmlschema-1/#Selector

and matches the production



  Path ::= ('.//')? ( Step '/' )* ( Step | '@' NameTest )

Returns a positive number in case of success and -1 in case of error

=end item1


=head1 METHODS PROCESSING ATTRIBUTES

=begin item1
attributeCount()

Provides the number of attributes of the current node.

=end item1

=begin item1
hasAttributes()

Whether the node has attributes.

=end item1

=begin item1
getAttribute(name)

Provides the value of the attribute with the specified qualified name.

Returns a string containing the value of the specified attribute, or undef in
case of error.

=end item1

=begin item1
getAttributeNs(localName, namespaceURI)

Provides the value of the specified attribute.

Returns a string containing the value of the specified attribute, or undef in
case of error.

=end item1

=begin item1
getAttributeNo(no)

Provides the value of the attribute with the specified index relative to the
containing element.

Returns a string containing the value of the specified attribute, or undef in
case of error.

=end item1

=begin item1
isDefault()

Returns true if the current attribute node was generated from the default value
defined in the DTD.

=end item1

=begin item1
moveToAttribute(name)

Moves the position to the attribute with the specified local name and namespace
URI.

Returns True in case of success, Failure in case of error, False if not found

=end item1

=begin item1
moveToAttributeNo(no)

Moves the position to the attribute with the specified index relative to the
containing element.

Returns True in case of success, Failure in case of error, False if not found

=end item1

=begin item1
moveToAttributeNs(localName,namespaceURI)

Moves the position to the attribute with the specified local name and namespace
URI.

Returns True in case of success, Failure in case of error, False if not found

=end item1

=begin item1
moveToFirstAttribute()

Moves the position to the first attribute associated with the current node.

Returns True in case of success, Failure in case of error, False if not found

=end item1

=begin item1
moveToNextAttribute()

Moves the position to the next attribute associated with the current node.

Returns True in case of success, Failure in case of error, False if not found

=end item1

=begin item1
moveToElement()

Moves the position to the node that contains the current attribute node.

Returns True in case of success, Failure in case of error, False if not moved

=end item1

=begin item1
isNamespaceDecl()

Determine whether the current node is a namespace declaration rather than a
regular attribute.

Returns True if the current node is a namespace declaration, False if it is a regular
attribute or other type of node, or Failure in case of error.

=end item1


=head1 OTHER METHODS

=begin item1
lookupNamespace(prefix)

Resolves a namespace prefix in the scope of the current element.

Returns a string containing the namespace URI to which the prefix maps or undef
in case of error.

=end item1

=begin item1
encoding()

Returns a string containing the encoding of the document or Str:U in case of
error.

=end item1

=begin item1
standalone()

Determine the standalone status of the document being read. Returns 1 if the
document was declared to be standalone, 0 if it was declared to be not
standalone, or -1 if the document did not specify its standalone status or in
case of error.

=end item1

=begin item1
xmlVersion()

Determine the XML version of the document being read. Returns a string
containing the XML version of the document or undef in case of error.

=end item1

=begin item1
baseURI()

Returns the base URI of a given node.

=end item1

=begin item1
isValid()

Retrieve the validity status from the parser.

Returns True if valid, False if no, and Failure in case of error.

=end item1

=begin item1
xmlLang()

The xml:lang scope within which the node resides.

=end item1

=begin item1
lineNumber()

Provide the line number of the current parsing point.

=end item1

=begin item1
columnNumber()

Provide the column number of the current parsing point.

=end item1

=begin item1
byteConsumed()

This function provides the current index of the parser relative to the start of
the current entity. This function is computed in bytes from the beginning
starting at zero and finishing at the size in bytes of the file if parsing a
file. The function is of constant cost if the input is UTF-8 but can be costly
if run on non-UTF-8 input.

=end item1

=begin item1
setParserProp(prop => value, ...)

Change the parser processing behaviour by changing some of its internal
properties. The following properties are available with this function:
``load-ext-dtd'', ``complete-attributes'', ``validation'', ``expand-entities''.

Since some of the properties can only be changed before any read has been done,
it is best to set the parsing properties at the constructor.

Returns 0 if the call was successful, or -1 in case of error

=end item1

=begin item1
getParserProp(prop)

Get value of an parser internal property. The following property names can be
used: ``load-ext-dtd'', ``complete-attributes'', ``validation'',
``expand-entities''.

Returns the value, usually True, False, or Failure in case of error.

=end item1


=head1 DESTRUCTION

LibXML takes care of the reader object destruction when the last reference to
the reader object goes out of scope. The document tree is preserved, though, if
either of $reader.document or $reader.preserveNode was used and references to
the document tree exist.


=head1 NODE TYPES

The reader interface provides the following constants for node types (the
constant symbols are exported by default or if tag C<<<<<< :types >>>>>> is used).



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


=head1 STATES

The following constants represent the values returned by C<<<<<< readState() >>>>>>. They are exported by default, or if tag C<<<<<< :states >>>>>> is used:



  XML_READER_NONE      => -1
  XML_READER_START     =>  0
  XML_READER_ELEMENT   =>  1
  XML_READER_END       =>  2
  XML_READER_EMPTY     =>  3
  XML_READER_BACKTRACK =>  4
  XML_READER_DONE      =>  5
  XML_READER_ERROR     =>  6


=head1 SEE ALSO

L<<<<<< LibXML::Pattern >>>>>> for information about compiled patterns.

http://xmlsoft.org/html/libxml-xmlreader.html

http://dotgnu.org/pnetlib-doc/System/Xml/XmlTextReader.html


=head1 ORIGINAL IMPLEMENTATION

Heiko Klein, <H.Klein@gmx.net<gt> and Petr Pajas

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
