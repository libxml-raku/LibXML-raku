[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Document](https://libxml-raku.github.io/LibXML-raku/Document)

class LibXML::Document
----------------------

LibXML DOM Document Class

Synopsis
--------

    use LibXML::Document;
    # Only methods specific to Document nodes are listed here,
    # see the LibXML::Node documentation for other methods

    my LibXML::Document $doc  .= new: :$version, :$enc;
    $doc .= createDocument($version, $enc);
    $doc .= parse($string);

    my Str $URI = $doc.URI();
    $doc.setURI($URI);
    my Str $enc = $doc.encoding();
    $enc = $doc.actualEncoding();
    $doc.encoding = $new-encoding;
    my Version $doc-version = $doc.version();
    use LibXML::Document :XmlStandalone;
    if $doc.standalone == XmlStandaloneYes {...}
    $doc.standalone = XmlStandaloneNo;
    my Bool $is-compressed = $doc.input-compressed;
    my Int $zip-level = 5; # zip-level (0..9), or -1 for no compression
    $doc.compression = $zip-level;
    my Str $html-tidy = $doc.Str: :$format, :$html;
    my Str $xml-c14n = $doc.Str: :C14N, :$comments, :$xpath, :$exclusive, :$selector;
    my Str $xml-tidy = $doc.serialize: :$format;
    my Int $state = $doc.write: :$file, :$format;
    $state = $doc.save: :io($fh), :$format;
    my Str $html = $doc.Str: :html;
    $html = $doc.serialize-html();
    try { $doc.validate(); }
    if $doc.is-valid() { ... }
    if $doc.is-valid($elem) { ... }

    my LibXML::Element $root = $doc.documentElement();
    $dom.documentElement = $root;
    my LibXML::Element $element = $doc.createElement( $nodename );
    $element = $doc.createElementNS( $namespaceURI, $nodename );
    my LibXML::Text $text = $doc.createTextNode( $content_text );
    my LibXML::Comment $comment = $doc.createComment( $comment_text );
    my LibXML::Attr $attr = $doc.createAttribute($name [,$value]);
    $attr = $doc.createAttributeNS( namespaceURI, $name [,$value] );
    my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();
    my LibXML::CDATA $cdata = $doc.createCDATASection( $cdata_content );
    my LibXML::PI $pi = $doc.createProcessingInstruction( $target, $data );
    my LibXML::EntityRef $entref = $doc.createEntityReference($refname);
    my LibXML::Dtd $dtd = $doc.createInternalSubset( $rootnode, $public, $system);
    $dtd = $doc.createExternalSubset( $rootnode_name, $publicId, $systemId);
    $doc.importNode( $node );
    $doc.adoptNode( $node );
    $dtd = $doc.externalSubset;
    $dtd = $doc.internalSubset;
    $doc.externalSubset = $dtd;
    $doc.internalSubset = $dtd;
    $dtd = $doc.removeExternalSubset();
    $dtd = $doc.removeInternalSubset();
    my LibXML::Element @found = $doc.getElementsByTagName($tagname);
    @found = $doc.getElementsByTagNameNS($nsURI,$tagname);
    @found = $doc.getElementsByLocalName($localname);
    my LibXML::Element $node = $doc.getElementById($id);
    $doc.indexElements();

Description
-----------

The Document Class is in most cases the result of a parsing process. But sometimes it is necessary to create a Document from scratch. The DOM Document Class provides functions that conform to the DOM Core naming style.

It inherits all functions from [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) as specified in the DOM specification. This enables access to the nodes besides the root element on document level - a `DTD` for example. The support for these nodes is limited at the moment.

Exports
-------

### XML

A subset of LibXML::Document that have node-type `XML_DOCUMENT_NODE`. General characteristics include:

  * element and attribute names are case sensitive

  * opening and closing tags must always be paired

### HTML

A subset of LibXML::Document that have node-type `XML_HTML_DOCUMENT_NODE`. General characteristics include:

  * HTML Parsing converts element and attribute names to lowercase. Closing tags can usually be omitted.

### DOCB

A subset of LibXML::Document that have node-type `XML_DOCB_DOCUMENT_NODE`. XML documents of type DocBook

Methods
-------

Many functions listed here are documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/](http://www.w3.org/TR/DOM-Level-3-Core/)). Please refer to the specification for extensive documentation.

### method new

    method new(
      xmlDoc :$native,
      Str :$version,
      xmlEncodingStr :$enc, # e.g. 'utf-8', 'utf-16'
      Str :$URI,
      Bool :$html,
      Int :$compression
    ) returns LibXML::Document

### method createDocument

    multi method createDocument(Str() $version, xmlEncodingStr $enc
    ) returns LibXML::Document
    multi method createDocument(
         Str $URI?, QName $name?, Str $doc-type?
    )

Raku or DOM-style constructors for the document class. As parameters it takes the version string and (optionally) the encoding string. Simply calling *createDocument*() will create the document:

```xml
<?xml version="your version" encoding="your encoding"?>
```

Both parameters are optional. The default value for *$version* is `1.0`, of course. If the *$encoding* parameter is not set, the encoding will be left unset, which means UTF-8 is implied.

The call of *createDocument*() without any parameter will result the following code:

```xml
<?xml version="1.0"?>
```

### method URI

    my Str $URI = $doc.URI();
    $doc.URI = $URI;

Gets or sets the URI (or filename) of the original document. For documents obtained by parsing a string of a FH without using the URI parsing argument of the corresponding `parse_*` function, the result is a generated string unknown-XYZ where XYZ is some number; for documents created with the constructor `new`, the URI is undefined.

### method encoding

    my Str $enc = $doc.encoding();
    $doc.encoding = $new-encoding;

Gets or sets the encoding of the document.

  * The `.Str` method treats the encoding as a subset. Any characters that fall outside the encoding set are encoded as entities (e.g. `&nbsp;`)

  * The `.Blob` method will fully render the XML document in as a Blob with the specified encoding.

    my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
    print $doc.encoding; # prints ISO-8859-15
    my $xml-with-entities = $doc.Str;
    'encoded.xml'.IO.spurt( $doc.Blob, :bin);

### method actualEncoding

```raku
method actualEncoding() returns LibXML::Raw::xmlEncodingStr
```

Returns the encoding in which the XML will be output by $doc.Blob() or $doc.write.

This is usually the original encoding of the document as declared in the XML declaration and returned by $doc.encoding. If the original encoding is not known (e.g. if created in memory or parsed from a XML without a declared encoding), 'UTF-8' is returned.

    my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
    print $doc.encoding; # prints ISO-8859-15

### method version

```raku
method version() returns Version
```

Gets or sets the version of the document

### method standalone

    use LibXML::Document :XmlStandalone;
    if $doc.standalone == XmlStandaloneYes { ... }

Gets or sets the Numerical value of a documents XML declarations standalone attribute.

It returns

  * *1 (XmlStandaloneYes)* if standalone="yes" was found,

  * *0 (XmlStandaloneNo)* if standalone="no" was found and

  * *-1 (XmlStandaloneMu)* if standalone was not specified (default on creation).

### method setStandalone

```raku
method setStandalone(
    Numeric $_
) returns Mu
```

Alter the value of a documents standalone attribute.

    use LibXML::Document :XmlStandalone;
    $doc.setStandalone(XmlStandaloneYes);

Set it to

  * *1 (XmlStandaloneYes)* to set standalone="yes",

  * to *0 (XmlStandaloneNo)* to set standalone="no" or

  * to *-1 (XmlStandaloneMu)* to remove the standalone attribute from the XML declaration.

### method compression

```raku
method compression() returns Int
```

Gets or sets output compression

### method input-compressed

```raku
method input-compressed() returns Bool
```

Detect whether input was compressed

```raku
my LibXML::Document $doc .= parse<mydoc.xml.gz>;
if $doc.input-compressed {
    my $zip-level = 5;
    $doc.compression = $zip-level;
    $doc.write: :file<test.xml.gz>;
}
else {
    $doc.write: :file<test.xml>;
}
```

libxml2 allows reading of documents directly from gzipped files. The input-compressed method returns True if the input file was compressed.

If one intends to write the document directly to a file, it is possible to set the compression level for a given document. This level can be in the range from 0 to 8. If LibXML should not try to compress use *-1* (default).

Note that this feature will *only* work if libxml2 is compiled with zlib support (`LibXML.have-compression` is True) ``and `.parse: :file(...)` is used for input and `.write` is used for output.

### method Str

```raku
multi method Str(
        Bool :$skip-dtd,
        Bool :$format, Bool :$tag-expansion,
        Bool :$skip-xml-declaration,
        LibXML::Config :$config, # defaults for :$skip-dtd, :skip-xml-declaration and :tag-expansion
    ) returns Str;
```

*Str* is a serializing function, so the DOM Tree is serialized into an XML string, ready for output.

    $file.IO.spurt: $doc.Str;

regardless of the actual encoding of the document.

The optional *$format* flag sets the indenting of the output.

If $format is False, or omitted, the document is dumped as it was originally parsed

If $format is True, libxml2 will add ignorable white spaces, so the nodes content is easier to read. Existing text nodes will not be altered

libxml2 uses a hard-coded indentation of 2 space characters per indentation level. This value can not be altered at run-time.

Note that the `:C14N` and `:html` options match different multi-methods, with diffrent options, as below:

#### `multi method Str: :C14N($!)!, Bool :$comments, Bool :$exclusive, :$xpath`

    my Str $xml-c14   = $doc.Str: :C14N, :$comment, :$xpath;
    my Str $xml-ec14n = $doc.Str: :C14N, :exclusive, :$xpath, :@prefix;

C14N normalisation mode. See the documentation in [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node).

#### `multi method Str: :$html!, Bool :$format`

    my Str $html = $document.Str: :html;

*.Str: :html* serializes the tree to a string as HTML. With this method indenting is automatic and managed by libxml2 internally.

### method serialize

    my Str $xml-formatted = $doc.serialize(:$format);

Similar to Str(), but doesn't interpret `:skip-dtd`, `:html` or `:C14N` options. This function was name added to be more consistent with libxml2.

### method serialize-html

```raku
method serialize-html(
    Bool :$format = Bool::True
) returns Str
```

Serialize to HTML.

Equivalent to: .Str: :html, but doesn't allow `:skip-dtd` option.

### method Blob() returns Blob

    method Blob(
        xmlEncodingStr :$enc = self.encoding // 'UTF-8',
        Bool :$format,
        Bool :$tag-expansion
        Bool :$skip-dtd,
        Bool :$skip-xml-declaration,
        Bool :$force,
    ) returns Blob;

Returns a binary representation of the XML document and it decendants encoded as `:$enc`.

The option `:force` is needed to really allow the combination of a non-UTF8 encoding and :skip-xml-declaration.

### method write

```raku
method write(
    Str(Any) :$file!,
    Bool :$format = Bool::False
) returns UInt
```

Write to a name file

### method save-as

```raku
method save-as(
    Str(Any) $file
) returns UInt
```

Write to a name file (equivalent to $.write: :$file)

### is-valid

```raku
multi method is-valid(LibXML::Dtd $dtd? --> Bool)
multi method is-valid(LibXML::Schema $schema? --> Bool)
multi method is-valid(LibXML::RelaxNG $rng? --> Bool)
multi method is-valid(LibXML::Element $elem --> Bool)
multi method is-valid(LibXML::Element $elem, LibXML::Attr $attr)
```

Checks that the document, or a an element in the document, is valid. Returns either True or False.

Optionally accepts an element to check. The element may be at any level in the document, and is checked as a sub-tree in isolation.

You may also pass in a [LibXML::Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd) object, to validate the document against an external DTD:

```raku
unless $doc.is-valid($dtd) {
    warn("document is not valid!");
}
```

### method was-valid

```raku
method was-valid() returns Bool
```

Whether the document was valid when it was parsed

### method validate

```raku
multi method validate(LibXML::Dtd $dtd?)
multi method validate(LibXML::Schema $schema)
multi method validate(LibXML::RexlaxNG $rng)
multi method validate(LibXML::Element $elem)
multi method validate(LibXML::Element $elem, LibXML::Attr $attr)
```

Validates, either the entire document, or an individual element.

This is an exception throwing equivalent of is-valid. If the document is not valid it will throw an exception containing the error.

It is also possible to write: `$elem.validate` as a shortcut for `$elem.ownerDocument.validate($elem)` and `$elem.is-valid` as a shortcut for `$elem.ownerDocument.is-valid($elem)`

### method documentElement

```raku
method documentElement() returns LibXML::Element
```

Gets or sets the root element of the Document.

A document can have just one root element to contain the documents data. If the document resides in a different document tree, it is automatically imported.

### method createElement

```raku
method createElement(
    Str $name where { ... },
    Str :$href
) returns LibXML::Element
```

Creates a new Element Node bound to the DOM with the given tag (name), Optionally bound to a given name-space;

### method createElementNS

```raku
method createElementNS(
    Str $href,
    Str:D $name where { ... }
) returns LibXML::Element
```

equivalent to .createElement($name, :$href)

### multi method createAttribute

```raku
multi method createAttribute(
    Str:D $qname where { ... },
    Str $value = "",
    Str:D :$href!
) returns LibXML::Attr
```

Creates a new Attribute node

### multi method createAttributeNS

```raku
multi method createAttributeNS(
    Str $href,
    Str:D $qname where { ... },
    Str $value = ""
) returns LibXML::Attr
```

Creates an Attribute bound to a name-space.

### method createDocumentFragment

```raku
method createDocumentFragment() returns LibXML::DocumentFragment
```

Creates a Document Fragment

### method createTextNode

```raku
method createTextNode(
    Str $content
) returns LibXML::Text
```

Creates a Text Node bound to the DOM.

### method createComment

```raku
method createComment(
    Str $content
) returns LibXML::Comment
```

Create a Comment Node bound to the DOM

### method createCDATASection

```raku
method createCDATASection(
    Str $content
) returns LibXML::CDATA
```

Create a CData Section bound to the DOM

### method createEntityReference

```raku
method createEntityReference(
    Str $name
) returns LibXML::EntityRef
```

Creates an Entity Reference

If a document has a DTD specified, one can create entity references by using this function. If one wants to add a entity reference to the document, this reference has to be created by this function.

An entity reference is unique to a document and cannot be passed to other documents as other nodes can be passed.

*NOTE:* A text content containing something that looks like an entity reference, will not be expanded to a real entity reference unless it is a predefined entity

    my Str $text = '&foo;';
    $some_element.appendText( $text );
    print $some_element.textContent; # prints "&amp;foo;"

### method createExternalSubset

```raku
method createExternalSubset(
    Str $name,
    Str $external-id,
    Str $system-id
) returns LibXML::Dtd
```

Creates a new external subset

This function is similar to `createInternalSubset()` but this DTD is considered to be external and is therefore not added to the document itself. Nevertheless it can be used for validation purposes.

### method createInternalSubset

```raku
method createInternalSubset(
    Str $name,
    Str $external-id,
    Str $system-id
) returns LibXML::Dtd
```

Creates a new Internal Subset

### method createInternalSubset

    my LibXML::Dtd
    $dtd = $doc.createInternalSubset( $rootnode, $public, $system);

This function creates and adds an internal subset to the given document. Because the function automatically adds the DTD to the document there is no need to add the created node explicitly to the document.

    my LibXML::Document $doc = LibXML::Document.new();
    my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", undef, "foo.dtd" );

will result in the following XML document:

```xml
<?xml version="1.0"?>
<!DOCTYPE foo SYSTEM "foo.dtd">
```

By setting the public parameter it is possible to set PUBLIC DTDs to a given document. So

    my LibXML::Document $doc = LibXML::Document.new();
    my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", "-//FOO//DTD FOO 0.1//EN", undef );

will cause the following declaration to be created on the document:

```xml
<?xml version="1.0"?>
<!DOCTYPE foo PUBLIC "-//FOO//DTD FOO 0.1//EN">
```

### method createDTD

```raku
method createDTD(
    Str $name,
    Str $external-id,
    Str $system-id
) returns LibXML::Dtd
```

Create a new external DTD

### method getEntity

```raku
method getEntity(
    Str $name
) returns LibXML::Dtd::Entity
```

Lookup an entity in the document

Searches any internal subset, external subset, and predefined entities

### method importNode

```raku
method importNode(
    LibXML::Node:D $node
) returns LibXML::Node
```

Imports a node from another DOM

If a node is not part of a document, it can be imported to another document. As specified in DOM Level 2 Specification the Node will not be altered or removed from its original document (`$node.cloneNode(:deep)` will get called implicitly).

### method adoptNode

```raku
method adoptNode(
    LibXML::Node:D $node
) returns LibXML::Node
```

Adopts a node from another DOM

If a node is not part of a document, it can be adopted by another document. As specified in DOM Level 3 Specification the Node will not be altered but it will removed from its original document.

After a document adopted a node, the node, its attributes and all its descendants belong to the new document. Because the node does not belong to the old document, it will be unlinked from its old location first.

*NOTE:* Don't try to use importNode() or adoptNode() to import sub-trees that contain entity references - even if the entity reference is the root node of the sub-tree. This will cause serious problems to your program. This is a limitation of libxml2 and not of LibXML itself.

### method getDocumentElement

```raku
method getDocumentElement() returns LibXML::Element
```

DOM compatible method to get the document element

### method setDocumentElement

```raku
method setDocumentElement(
    LibXML::Element:D $elem
) returns LibXML::Element
```

DOM compatible method to set the document element

Inserts a copy of the Dtd node into the document as its internal subset

```raku
my $new-dtd = $doc.setInternalSubset: $other-doc.getInternalSubset;
```

Note: At this stage, only the `name`, `publicId` and `systemId` are copied.

This method is currently most useful for setting the document-type of an XML or HTML document:

```raku
use LibXML;
use LibXML::Dtd;
use LibXML::Document;
my $htmlPublic = "-//W3C//DTD XHTML 1.0 Transitional//EN";
my $htmlSystem = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

my LibXML::Dtd:D $dtd = LibXML.createDocumentType('xhtml', $htmlPublic, $htmlSystem);
my Bool $html = $dtd.is-XHTML;
my LibXML::Document $doc .= new: :$html;
$doc.setInternalSubset: $dtd;
$doc.setDocumentElement: $doc.createElement('xhtml');
say $doc.Str;
# <!DOCTYPE xhtml PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
# <xhtml></xhtml>
```

### method removeInternalSubset

```raku
method removeInternalSubset() returns LibXML::Dtd
```

This method removes an external, if defined, from the document

If a document has an internal subset defined it can be removed from the document by using this function. The removed dtd node will be returned.

### method internalSubset

```raku
method internalSubset() returns LibXML::Dtd
```

Gets or sets the internal DTD for the document.

### method setExternalSubset

```raku
method setExternalSubset(
    LibXML::Dtd $dtd is copy,
    Bool :$validate
) returns LibXML::Dtd
```

This method sets a DTD node as an external subset of the given document.

If the :validate option is passed, the document is first validated against the DTD.

### method removeExternalSubset

```raku
method removeExternalSubset() returns LibXML::Dtd
```

This method removes any external subset from the document

If a document has an external subset defined it can be removed from the document by using this function. The removed dtd node will be returned.

### method externalSubset

```raku
method externalSubset() returns LibXML::Dtd
```

Gets or sets the external DTD for a document.

### method parse

    my LibXML::Document $doc .= parse($string, |%opts);

Calling `LibXML::Document.parse(|c)` is equivalent to calling `LibXML.parse(|c)`; See the parse method in [LibXML](https://libxml-raku.github.io/LibXML-raku).

### method processXIncludes

```raku
method processXIncludes(
    LibXML::Config :$config = Code.new,
    |c
) returns Mu
```

Expand XInclude flags

### method getElementsByTagName

    my LibXML::Element @nodes = $doc.getElementsByTagName($tagname);
    my LibXML::Node::Set $nodes = $doc.getElementsByTagName($tagname);

Implements the DOM Level 2 function

### method getElementsByTagNameNS

    my LibXML::Element @nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);
    my LibXML::Node::Set $nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);

Implements the DOM Level 2 function

### method getElementsByLocalName

    my LibXML::Element @nodes = $doc.getElementsByLocalName($localname);
    my LibXML::Node::Set $nodes = $doc.getElementsByLocalName($localname);

This allows the fetching of all nodes from a given document with the given Localname.

### method getElementById

```raku
method getElementById(
    Str:D $id
) returns LibXML::Element
```

Returns the element that has an ID attribute with the given value. If no such element exists, this returns LibXML::Element:U.

Note: the ID of an element may change while manipulating the document. For documents with a DTD, the information about ID attributes is only available if DTD loading/validation has been requested. For HTML documents parsed with the HTML parser ID detection is done automatically. In XML documents, all "xml:id" attributes are considered to be of type ID. You can test ID-ness of an attribute node with $attr.isId().

### method indexElements

```raku
method indexElements() returns Int
```

Index elements for faster XPath searching

This function causes libxml2 to stamp all elements in a document with their document position index which considerably speeds up XPath queries for large documents. It should only be used with static documents that won't be further changed by any DOM methods, because once a document is indexed, XPath will always prefer the index to other methods of determining the document order of nodes. XPath could therefore return improperly ordered node-lists when applied on a document that has been changed after being indexed. It is of course possible to use this method to re-index a modified document before using it with XPath again. This function is not a part of the DOM specification.

This function returns the number of elements indexed, -1 if error occurred, or -2 if this feature is not available in the running libxml2.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

