[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Reader](https://libxml-raku.github.io/LibXML-raku/Reader)

class LibXML::Reader
--------------------

Interface to libxml2 Pull Parser

Synopsis
--------

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

Description
-----------

This is a Raku interface to libxml2's pull-parser implementation xmlTextReader *http://xmlsoft.org/html/libxml-xmlreader.html*. Pull-parsers (such as StAX in Java, or XmlReader in C#) use an iterator approach to parse XML documents. They are easier to program than event-based parser (SAX) and much more lightweight than tree-based parser (DOM), which load the complete tree into memory.

The Reader acts as a cursor going forward on the document stream and stopping at each node on the way. At every point, the DOM-like methods of the Reader object allow one to examine the current node (name, namespace, attributes, etc.)

The user's code keeps control of the progress and simply calls the `read()` function repeatedly to progress to the next node in the document order. Other functions provide means for skipping complete sub-trees, or nodes until a specific element, etc.

At every time, only a very limited portion of the document is kept in the memory, which makes the API more memory-efficient than using DOM. However, it is also possible to mix Reader with DOM. At every point the user may copy the current node (optionally expanded into a complete sub-tree) from the processed document to another DOM tree, or to instruct the Reader to collect sub-document in form of a DOM tree consisting of selected nodes.

Reader API also supports namespaces, xml:base, entity handling, DTD, Schema and RelaxNG validation support

The naming of methods compared to libxml2 and C# XmlTextReader has been changed slightly to match the conventions of LibXML. Some functions have been changed or added with respect to the C interface.

Constructor
-----------

Depending on the XML source, the Reader object can be created with either of:

    my LibXML::Reader $reader .= new( file => "file.xml", ... );
    my LibXML::Reader $reader .= new( string => $xml_string, ... );
    my LibXML::Reader $reader .= new( io => $file_handle, ... );
    my LibXML::Reader $reader .= new( fd => $file_handle.native_descriptor, ... );
    my LibXML::Reader $reader .= new( DOM => $dom, ... );

where ... are reader options described below in [Reader options](Reader options) or various parser options described in [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser). The constructor recognizes the following XML sources:

### Source specification

  * Str :$file

    Read XML from a local file or URL.

  * Str :$string

    Read XML from a string.

  * IO::Handle :$io

    Read XML as a Raku IO::Handle object.

  * UInt :$fd

    Read XML from a file descriptor number. Possibly faster than IO.

  * LibXML::Document :$DOM

    Use reader API to walk through a pre-parsed [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document).

### Reader options

  * :$encoding

    override document encoding.

  * RelaxNG => $rng-schema

    can be used to pass either a [LibXML::RelaxNG](https://libxml-raku.github.io/LibXML-raku/RelaxNG) object or a filename or URL of a RelaxNG schema to the constructor. The schema is then used to validate the document as it is processed.

  * Schema => $xsd-schema

    can be used to pass either a [LibXML::Schema](https://libxml-raku.github.io/LibXML-raku/Schema) object or a filename or URL of a W3C XSD schema to the constructor. The schema is then used to validate the document as it is processed.

  * ...

    the reader further supports various parser options described in [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser) (specifically those labeled by /reader/). 

Methods Controlling Parsing Progress
------------------------------------

### method read

```perl6
method read() returns Bool
```

Moves the position to the next node in the stream, exposing its properties.

Returns True if the node was read successfully, False if there is no more nodes to read, or Failure in case of error

### method readAttributeValue

```perl6
method readAttributeValue() returns Bool
```

Parses an attribute value into one or more Text and EntityReference nodes.

Returns True in case of success, False if the reader was not positioned on an attribute node or all the attribute values have been read, or Failure in case of error.

### method readState

```perl6
method readState() returns UInt
```

Gets the read state of the reader.

Returns the state value, or Failure in case of error. The module exports constants for the Reader states, see STATES below.

### method depth

```perl6
method depth() returns UInt
```

The depth of the node in the tree, starts at 0 for the root node.

### method next

```perl6
method next() returns Bool
```

Skip to the node following the current one in the document order while avoiding the sub-tree if any.

Returns True if the node was read successfully, False if there is no more nodes to read, or Failure in case of error.

### method nextElement

```perl6
method nextElement(
    Str $local-name? where { ... },
    Str $URI?
) returns Bool
```

Skip nodes following the current one in the document order until a specific element is reached.

The element's name must be equal to a given localname if defined, and its namespace must equal to a given nsURI if defined. Either of the arguments can be undefined (or omitted, in case of the latter or both).

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

### method nextPatternMatch

```perl6
method nextPatternMatch(
    LibXML::Pattern:D $pattern
) returns Bool
```

Skip nodes following the current one in the document order until an element matching a given compiled pattern is reached.

See [LibXML::Pattern](https://libxml-raku.github.io/LibXML-raku/Pattern) for information on compiled patterns. See also the `matchesPattern` method.

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

### method skipSiblings

```perl6
method skipSiblings() returns Bool
```

Skip all nodes on the same or lower level until the first node on a higher level is reached.

In particular, if the current node occurs in an element, the reader stops at the end tag of the parent element, otherwise it stops at a node immediately following the parent node.

Returns True if successful, False if end of the document is reached, or Failure in case of error.

### method nextSibling

```perl6
method nextSibling() returns Bool
```

Skips to the node following the current one in the document order while avoiding the sub-tree if any.

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

### method nextSiblingElement

```perl6
method nextSiblingElement(
    Str $name? where { ... },
    Str $URI?
) returns Mu
```

Like nextElement but only processes sibling elements of the current node (moving forward using nextSibling() rather than read(), internally).

Returns True if the element was found, False if there is no more nodes to read, or Failure in case of error.

### method finish

```perl6
method finish() returns Bool
```

Skip all remaining nodes in the document, reaching end of the document.

Returns True if successful, False in case of error.

### method close

```perl6
method close() returns Bool
```

This method releases any resources allocated by the current instance and closes underlying input.

It returns False on failure and True on success. This method is automatically called by the destructor when the reader is forgotten, therefore you do not have to call it directly.

Methods Extracting Information
------------------------------

### method name

```perl6
method name() returns LibXML::Types::QName
```

Returns the qualified name of the current node.

Equal to (Prefix:)LocalName.

### method nodeType

```perl6
method nodeType() returns UInt
```

Returns the type of the current node.

See NODE TYPES below.

### method localName

```perl6
method localName() returns LibXML::Types::NCName
```

Returns he local name of the node.

### method prefix

```perl6
method prefix() returns LibXML::Types::NCName
```

Returns the prefix of the namespace associated with the node.

### method namespaceURI

```perl6
method namespaceURI() returns Str
```

Returns the URI defining the namespace associated with the node.

### method isEmptyElement

```perl6
method isEmptyElement() returns Bool
```

Check if the current node is empty.

This is a bit bizarre in the sense that <a/> will be considered empty while <a></a> will not.

### method hasValue

```perl6
method hasValue() returns Bool
```

Returns True if the node can have a text value.

### method value

```perl6
method value() returns Str
```

Provides the text value of the node if present or Str:U if not available.

### method readInnerXml

```perl6
method readInnerXml() returns Str
```

Reads the contents of the current node, including child nodes and markup.

Returns a string containing the XML of the node's content, or Str:U if the current node is neither an element nor attribute, or has no child nodes.

### method readOuterXml

```perl6
method readOuterXml() returns Str
```

Reads the contents of the current node, including child nodes and markup.

Returns a string containing the XML of the node including its content, or undef if the current node is neither an element nor attribute.

### method nodePath

```perl6
method nodePath() returns Mu
```

Returns a canonical location path to the current element from the root node to

  * Namespaced elements are matched by '*', because there is no way to declare prefixes within XPath patterns.

  * Unlike `LibXML::Node::nodePath()`, this function does not provide sibling counts (i.e. instead of e.g. '/a/b[1]' and '/a/b[2]' you get '/a/b' for both matches). 

### method matchesPattern

```perl6
method matchesPattern(
    LibXML::Pattern:D $pattern
) returns Bool
```

Returns a true value if the current node matches a compiled pattern.

  * See [LibXML::Pattern](https://libxml-raku.github.io/LibXML-raku/Pattern) for information on compiled patterns.

  * See also the `nextPatternMatch` method.

Methods Extracting DOM Nodes
----------------------------

### method document

```perl6
method document() returns Mu
```

Provides access to the document tree built by the reader.

  * This function can be used to collect the preserved nodes (see `preserveNode()` and preservePattern).

  * CAUTION: Never use this function to modify the tree unless reading of the whole document is completed!

### method copyCurrentNode

```perl6
method copyCurrentNode(
    Bool :$deep
) returns LibXML::Node
```

This function is similar a DOM function copyNode(). It returns a copy of the currently processed node as a corresponding DOM object.

  * Use :deep to obtain the full sub-tree.

### method preserveNode

```perl6
method preserveNode() returns LibXML::Node
```

This tells the XML Reader to preserve the current node in the document tree.

A document tree consisting of the preserved nodes and their content can be obtained using the method `document()` once parsing is finished.

Returns the node or LibXML::Node:U in case of error.

### method preservePattern

```perl6
method preservePattern(
    Str:D $pattern,
    :%ns
) returns UInt
```

This tells the XML Reader to preserve all nodes matched by the pattern (which is a streaming XPath subset).

A document tree consisting of the preserved nodes and their content can be obtained using the method `document()` once parsing is finished.

An :%ns may be used to pass a mapping prefixes used by the XPath to namespace URIs.

The XPath subset available with this function is described at [http://www.w3.org/TR/xmlschema-1/#Selector](http://www.w3.org/TR/xmlschema-1/#Selector) and matches the production

```bnf
Path ::= ('.//')? ( Step '/' )* ( Step | '@' NameTest )
```

Returns a positive number in case of success or Failure in case of error

Methods Processing Attributes
-----------------------------

### method attributeCount

```perl6
method attributeCount() returns UInt
```

Provides the number of attributes of the current node.

### method hasAttributes

```perl6
method hasAttributes() returns Bool
```

Whether the node has attributes.

### method getAttribute

```perl6
method getAttribute(
    Str $name where { ... }
) returns Str
```

Provides the value of the attribute with the specified qualified name.

Returns a string containing the value of the specified attribute, or Str:U in case of error.

### method getAttributeNs

```perl6
method getAttributeNs(
    Str $local-name where { ... },
    Str $namespace-URI
) returns Str
```

Provides the value of the specified attribute in a given namespace

### method getAttributeNo

```perl6
method getAttributeNo(
    Int $i where { ... }
) returns Str
```

Provides the value of the attribute with the specified index relative to the containing element.

### method isDefault

```perl6
method isDefault() returns Bool
```

Returns True if the current attribute node was generated from the default value defined in the DTD.

### method moveToAttribute

```perl6
method moveToAttribute(
    Str $name where { ... }
) returns Bool
```

Moves the position to the attribute with the specified name

Returns True in case of success, Failure in case of error, False if not found

### method moveToAttributeNo

```perl6
method moveToAttributeNo(
    Int $i
) returns Bool
```

Moves the position to the attribute with the specified index relative to the containing element.

Returns True in case of success, Failure in case of error, False if not found

### method moveToAttributeNs

```perl6
method moveToAttributeNs(
    Str:D $name where { ... },
    Str $URI
) returns Mu
```

Moves the position to the attribute with the specified local name and namespace URI.

Returns True in case of success, Failure in case of error, False if not found

### method moveToFirstAttribute

```perl6
method moveToFirstAttribute() returns Bool
```

Moves the position to the first attribute associated with the current node.

Returns True in case of success, Failure in case of error, False if not found

### method moveToNextAttribute

```perl6
method moveToNextAttribute() returns Bool
```

Moves the position to the next attribute associated with the current node.

Returns True in case of success, Failure in case of error, False if not found

### method moveToElement

```perl6
method moveToElement() returns Bool
```

Moves the position to the node that contains the current attribute node.

Returns True in case of success, Failure in case of error, False if not moved

### method isNamespaceDecl

```perl6
method isNamespaceDecl() returns Bool
```

Determine whether the current node is a namespace declaration rather than a regular attribute.

Returns True if the current node is a namespace declaration, False if it is a regular attribute or other type of node, or Failure in case of error.

Other Methods
-------------

### method lookupNamespace

```perl6
method lookupNamespace(
    Str $URI
) returns LibXML::Types::NCName
```

Resolves a namespace prefix in the scope of the current element.

Returns a string containing the namespace URI to which the prefix maps or undef in case of error.

### method encoding

```perl6
method encoding() returns LibXML::Raw::xmlEncodingStr
```

Get the encoding of the document being read

### method standalone

```perl6
method standalone() returns Int
```

Returns a string containing the encoding of the document or Str:U in case of error. Determine the standalone status of the document being read.

    use LibXML::Document :XmlStandalone;
    if $reader.standalone == XmlStandaloneYes { ... }

Gets or sets the Numerical value of a documents XML declarations standalone attribute.

It returns

  * *1 (XmlStandaloneYes)* if standalone="yes" was found,

  * *0 (XmlStandaloneNo)* if standalone="no" was found and

  * *-1 (XmlStandaloneMu)* if standalone was not specified (default on creation).

### method xmlVersion

```perl6
method xmlVersion() returns Version
```

Determine the XML version of the document being read

### method baseURI

```perl6
method baseURI() returns Str
```

Returns the base URI of the current node.

### method isValid

```perl6
method isValid() returns Bool
```

Retrieve the validity status from the parser.

Returns True if valid, False if no, and Failure in case of error.

### method xmlLang

```perl6
method xmlLang() returns Str
```

The xml:lang scope within which the current node resides.

### method lineNumber

```perl6
method lineNumber() returns UInt
```

Provide the line number of the current parsing point.

### method columnNumber

```perl6
method columnNumber() returns UInt
```

Provide the column number of the current parsing point.

### method byteConsumed

```perl6
method byteConsumed() returns UInt
```

This function provides the current index of the parser relative to the start of the current entity.

This function is computed in bytes from the beginning starting at zero and finishing at the size in bytes of the file if parsing a file. The function is of constant cost if the input is UTF-8 but can be costly if run on non-UTF-8 input.

### method setParserProp

```perl6
method setParserProp(
    *%props
) returns Hash
```

Change the parser processing behaviour by changing some of its internal properties.

The following properties are available with this function: `load-ext-dtd`, `complete-attributes`, `validation`, `expand-entities`

Since some of the properties can only be changed before any read has been done, it is best to set the parsing properties at the constructor.

Returns True if the call was successful, or Failure in case of error

### multi method getParserProp

```perl6
multi method getParserProp(
    Str:D $opt
) returns Bool
```

Get value of an parser internal property.

The following property names can be used: `load-ext-dtd`, `complete-attributes`, `validation`, `expand-entities`.

Returns the value, usually True, False, or Failure in case of error.

### method have-reader

```perl6
method have-reader() returns Mu
```

Ensure libxml2 has been compiled with the reader pull-parser enabled

Destruction
-----------

LibXML takes care of the reader object destruction when the last reference to the reader object goes out of scope. The document tree is preserved, though, if either of $reader.document or $reader.preserveNode was used and references to the document tree exist.

Node Types
----------

The reader interface provides the following constants for node types (the constant symbols are exported by default or if tag `:types` is used).

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

States
------

The following constants represent the values returned by `readState()`. They are exported by default, or if tag `:states` is used:

    XML_READER_NONE      => -1
    XML_READER_START     =>  0
    XML_READER_ELEMENT   =>  1
    XML_READER_END       =>  2
    XML_READER_EMPTY     =>  3
    XML_READER_BACKTRACK =>  4
    XML_READER_DONE      =>  5
    XML_READER_ERROR     =>  6

SEE ALSO
--------

[LibXML::Pattern](https://libxml-raku.github.io/LibXML-raku/Pattern) for information about compiled patterns.

[http://xmlsoft.org/html/libxml-xmlreader.html](http://xmlsoft.org/html/libxml-xmlreader.html)

[http://dotgnu.org/pnetlib-doc/System/Xml/XmlTextReader.html](http://dotgnu.org/pnetlib-doc/System/Xml/XmlTextReader.html)

Original Perl Implementation
----------------------------

Heiko Klein, <H.Klein@gmx.net> and Petr Pajas

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

