NAME
====

LibXML::Document - LibXML DOM Document Class

SYNOPSIS
========

    use LibXML::Document;
    # Only methods specific to Document nodes are listed here,
    # see the LibXML::Node manpage for other methods

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
    my Int $ziplevel = $doc.compression; # zip-level or -1
    $doc.compression = $ziplevel;
    my Str $html-tidy = $dom.Str(:$format, :$HTML);
    my Str $xml-c14n = $doc.Str: :C14N, :$comments, :$xpath, :$exclusive, :$selector;
    my Str $xml-tidy = $doc.serialize(:$format);
    my Int $state = $doc.write: :io($filename), :$format;
    $state = $doc.write: :io($fh), :$format;
    my Str $html = $doc.Str(:HTML);
    $html = $doc.serialize-html();
    try { $dom.validate(); }
    if $dom.is-valid() { ... }

    my LibXML::Element $root = $dom.documentElement();
    $dom.documentElement = $root;
    my LibXML::Element $element = $dom.createElement( $nodename );
    $element = $dom.createElementNS( $namespaceURI, $nodename );
    my LibXML::Text $text = $dom.createTextNode( $content_text );
    my LibXML::Comment $comment = $dom.createComment( $comment_text );
    my LibXML::Attr $attr = $doc.createAttribute($name [,$value]);
    $attr = $doc.createAttributeNS( namespaceURI, $name [,$value] );
    my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();
    my LibXML::CDATASection $cdata = $dom.createCDATASection( $cdata_content );
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

DESCRIPTION
===========

The Document Class is in most cases the result of a parsing process. But sometimes it is necessary to create a Document from scratch. The DOM Document Class provides functions that conform to the DOM Core naming style.

It inherits all functions from [LibXML::Node ](LibXML::Node ) as specified in the DOM specification. This enables access to the nodes besides the root element on document level - a `DTD ` for example. The support for these nodes is limited at the moment.

METHODS
=======

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/ ](http://www.w3.org/TR/DOM-Level-3-Core/ )). Please refer to the specification for extensive documentation.

  * new

        my LibXML::Document $dom .= new;

  * createDocument

        $dom = LibXML::Document.createDocument( $version, $encoding );

    DOM-style constructor for the document class. As parameters it takes the version string and (optionally) the encoding string. Simply calling *createDocument *() will create the document:

        <?xml version="your version" encoding="your encoding"?>

    Both parameters are optional. The default value for *$version * is `1.0 `, of course. If the *$encoding * parameter is not set, the encoding will be left unset, which means UTF-8 is implied.

    The call of *createDocument *() without any parameter will result the following code:

        <?xml version="1.0"?>

    Alternatively one can call this constructor directly from the LibXML class level, to avoid some typing. This will not have any effect on the class instance, which is always LibXML::Document.

        my $document = LibXML.createDocument( "1.0", "UTF-8" );

    is therefore a shortcut for

        my $document = LibXML::Document.createDocument( "1.0", "UTF-8" );

  * parse

        my LibXML::Document $doc .= parse($string, |%opts);

        Calling C<LibXML::Document.parse(|c)> is equivalent to calling C<LibXML.parse(|c)>; See the parse method in L<LibXML>.

  * URI

        my Str $URI = $doc.URI();
        $doc.URI = $URI;

    Gets or sets the URI (or filename) of the original document. For documents obtained by parsing a string of a FH without using the URI parsing argument of the corresponding `parse_* ` function, the result is a generated string unknown-XYZ where XYZ is some number; for documents created with the constructor `new `, the URI is undefined.

  * encoding

        my Str $enc = $doc.encoding();
        $doc.encoding = $new-encoding;

    Gets or sets the encoding of the document.

      * The `.Str` method treats the encoding as a subset. Any characters that fall outside the encoding set are encoded as entities (e.g. `&nbsp;`)

      * The `.Blob` method will fully render the XML document in as a Blob with the specified encoding.

        my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
        print $doc.encoding; # prints ISO-8859-15
        my $xml-with-entities = $doc.Str;
        'encoded.xml'.IO.spurt( $doc.Blob, :bin);

  *     actualEncoding

      my Str $enc = $doc.actualEncoding();

    returns the encoding in which the XML will be output by $doc.Blob() or $doc.write. This is usually the original encoding of the document as declared in the XML declaration and returned by $doc.encoding. If the original encoding is not known (e.g. if created in memory or parsed from a XML without a declared encoding), 'UTF-8' is returned.

        my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
        print $doc.encoding; # prints ISO-8859-15

  * version

        my Version $v = $doc.version();

    returns the version of the document

    *getVersion() * is an alternative getter function.

  * standalone

        use LibXML::Document :XmlStandalone;
        if $doc.standalone == XmlStandaloneYes { ... }

    This function returns the Numerical value of a documents XML declarations standalone attribute. It returns *1 (XmlStandaloneYes) * if standalone="yes" was found, *0 (XmlStandaloneNo) * if standalone="no" was found and *-1 (XmlStandaloneMu) * if standalone was not specified (default on creation).

  * setStandalone

        use LibXML::Document :XmlStandalone;
        $doc.setStandalone(XmlStandaloneYes);

    Through this method it is possible to alter the value of a documents standalone attribute. Set it to *1 (XmlStandaloneYes) * to set standalone="yes", to *0 (XmlStandaloneNo) * to set standalone="no" or set it to *-1 (XmlStandaloneMu) * to remove the standalone attribute from the XML declaration.

  * compression

        my Int $compression = $doc.compression;
        $doc.compression = $ziplevel;

    libxml2 allows reading of documents directly from gzipped files. In this case the compression variable is set to the compression level of that file (0-8). If LibXML parsed a different source or the file wasn't compressed, the returned value will be *-1 *.

    If one intends to write the document directly to a file, it is possible to set the compression level for a given document. This level can be in the range from 0 to 8. If LibXML should not try to compress use *-1 * (default).

    Note that this feature will *only * work if libxml2 is compiled with zlib support and `.write` is used for output.

  * Str

        my Str $xml = $dom.Str(:$format);

    *Str * is a serializing function, so the DOM Tree is serialized into an XML string, ready for output.

        $file.IO.spurt: $doc.Str;

    regardless of the actual encoding of the document. See the section on encodings in [LibXML ](LibXML ) for more details.

    The optional *$format * parameter sets the indenting of the output. This parameter is expected to be an `integer ` value, that specifies that indentation should be used. The format parameter can have three different values if it is used:

    If $format is 0, than the document is dumped as it was originally parsed

    If $format is 1, libxml2 will add ignorable white spaces, so the nodes content is easier to read. Existing text nodes will not be altered

    If $format is 2 (or higher), libxml2 will act as $format == 1 but it add a leading and a trailing line break to each text node.

    libxml2 uses a hard-coded indentation of 2 space characters per indentation level. This value can not be altered on run-time.

  * Str: :C14N

        my Str $xml-c14   = $doc.Str: :C14N, :$comment, :$xpath;
        my Str $xml-ec14n = $doc.Str: :C14N, :exclusive $xpath, :@prefix;

    C14N Normalisation. See the documentation in [LibXML::Node ](LibXML::Node ).

  * serialize

        my Str $xml-formatted = $doc.serialize(:$format);

    An alias for toString(). This function was name added to be more consistent with libxml2.

  * write

        my Int $state = $doc.write: :io($filename), :$format;

    This function is similar to Str(), but it writes the document directly into a filesystem. This function is very useful, if one needs to store large documents.

    The format parameter has the same behaviour as in Str().

  * Str: :HTML

        my Str $html = $document.Str: :HTML;

    *.Str: :HTML * serializes the tree to a byte string in the document encoding as HTML. With this method indenting is automatic and managed by libxml2 internally.

  * serialize-html

        my Str $html = $document.serialize-html();

    An alias for Str: :HTML.

  * is-valid

        my Bool $valid = $dom.is-valid();

    Returns either True or False depending on whether the DOM Tree is a valid Document or not.

    You may also pass in a [LibXML::Dtd ](LibXML::Dtd ) object, to validate against an external DTD:

    unless $dom.is-valid(:$dtd) {
         warn("document is not valid!");
     }

  * validate

        $dom.validate();

    This is an exception throwing equivalent of is_valid. If the document is not valid it will throw an exception containing the error. This allows you much better error reporting than simply is_valid or not.

    Again, you may pass in a DTD object

  * documentElement

        my LibXML::Element $root = $dom.documentElement();
        $dom.documentElement = $root;

    Returns the root element of the Document. A document can have just one root element to contain the documents data.

    This function also enables you to set the root element for a document. The function supports the import of a node from a different document tree, but does not support a document fragment as $root.

  * createElement

        my LibXML::Element $element = $dom.createElement( $nodename );

    This function creates a new Element Node bound to the DOM with the name `$nodename `.

  * createElementNS

        my LibXML::Element $element = $dom.createElementNS( $namespaceURI, $nodename );

    This function creates a new Element Node bound to the DOM with the name `$nodename ` and placed in the given namespace.

  * createTextNode

        my LibXML::Text $text = $dom.createTextNode( $content_text );

    As an equivalent of *createElement *, but it creates a *Text Node * bound to the DOM.

  * createComment

        my LibXML::Comment $comment = $dom.createComment( $comment_text );

    As an equivalent of *createElement *, but it creates a *Comment Node * bound to the DOM.

  * createAttribute

        my LibXML::Attr $attrnode = $doc.createAttribute($name [,$value]);

    Creates a new Attribute node.

  * createAttributeNS

        my LibXML::Attr $attrnode = $doc.createAttributeNS( namespaceURI, $name [,$value] );

    Creates an Attribute bound to a namespace.

  * createDocumentFragment

        my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();

    This function creates a DocumentFragment.

  * createCDATASection

        my LibXML::CDATASection $cdata = $dom.createCDATASection( $cdata_content );

    Similar to createTextNode and createComment, this function creates a CDataSection bound to the current DOM.

  * createProcessingInstruction

        my LibXML::PI $pi = $doc.createProcessingInstruction( $target, $data );

    create a processing instruction node.

    Since this method is quite long one may use its short form *createPI() *.

  * createEntityReference

        my LibXML::EntityRef $entref = $doc.createEntityReference($refname);

    If a document has a DTD specified, one can create entity references by using this function. If one wants to add a entity reference to the document, this reference has to be created by this function.

    An entity reference is unique to a document and cannot be passed to other documents as other nodes can be passed.

    *NOTE: * A text content containing something that looks like an entity reference, will not be expanded to a real entity reference unless it is a predefined entity

        my Str $text = '&foo;';
        $some_element.appendText( $text );
        print $some_element.textContent; # prints "&amp;foo;"

  * createInternalSubset

        my LibXML::Dtd
        $dtd = $doc.createInternalSubset( $rootnode, $public, $system);

    This function creates and adds an internal subset to the given document. Because the function automatically adds the DTD to the document there is no need to add the created node explicitly to the document.

        my LibXML::Document $doc = LibXML::Document.new();
        my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", undef, "foo.dtd" );

    will result in the following XML document:

        <?xml version="1.0"?>
         <!DOCTYPE foo SYSTEM "foo.dtd">

    By setting the public parameter it is possible to set PUBLIC DTDs to a given document. So

        my LibXML::Document $doc = LibXML::Document.new();
        my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", "-//FOO//DTD FOO 0.1//EN", undef );

    will cause the following declaration to be created on the document:

        <?xml version="1.0"?>
        <!DOCTYPE foo PUBLIC "-//FOO//DTD FOO 0.1//EN">

  * createExternalSubset

        $dtd = $doc.createExternalSubset( $rootnode_name, $publicId, $systemId);

    This function is similar to `createInternalSubset() ` but this DTD is considered to be external and is therefore not added to the document itself. Nevertheless it can be used for validation purposes.

  * importNode

        $document.importNode( $node );

    If a node is not part of a document, it can be imported to another document. As specified in DOM Level 2 Specification the Node will not be altered or removed from its original document (`$node.cloneNode(1) ` will get called implicitly).

    *NOTE: * Don't try to use importNode() to import sub-trees that contain an entity reference - even if the entity reference is the root node of the sub-tree. This will cause serious problems to your program. This is a limitation of libxml2 and not of LibXML itself.

  * adoptNode

        $document.adoptNode( $node );

    If a node is not part of a document, it can be imported to another document. As specified in DOM Level 3 Specification the Node will not be altered but it will removed from its original document.

    After a document adopted a node, the node, its attributes and all its descendants belong to the new document. Because the node does not belong to the old document, it will be unlinked from its old location first.

    *NOTE: * Don't try to adoptNode() to import sub-trees that contain entity references - even if the entity reference is the root node of the sub-tree. This will cause serious problems to your program. This is a limitation of libxml2 and not of LibXML itself.

  * externalSubset

        my LibXML::Dtd $dtd = $doc.externalSubset;

    If a document has an external subset defined it will be returned by this function.

    *NOTE * Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in LibXML is still limited. In particular one may not want use common node function on doctype declaration nodes!

  * internalSubset

        my LibXML::Dtd $dtd = $doc.internalSubset;

    If a document has an internal subset defined it will be returned by this function.

    *NOTE * Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in LibXML is still limited. In particular one may not want use common node function on doctype declaration nodes!

  * setExternalSubset

        $doc.setExternalSubset($dtd);

    *EXPERIMENTAL! *

    This method sets a DTD node as an external subset of the given document.

  * setInternalSubset

        $doc.setInternalSubset($dtd);

    *EXPERIMENTAL! *

    This method sets a DTD node as an internal subset of the given document.

  * removeExternalSubset

        my $dtd = $doc.removeExternalSubset();

    *EXPERIMENTAL! *

    If a document has an external subset defined it can be removed from the document by using this function. The removed dtd node will be returned.

  * removeInternalSubset

        my $dtd = $doc.removeInternalSubset();

    *EXPERIMENTAL! *

    If a document has an internal subset defined it can be removed from the document by using this function. The removed dtd node will be returned.

  * getElementsByTagName

        my LibXML::Element @nodes = $doc.getElementsByTagName($tagname);
        my LibXML::Node::Set $nodes = $doc.getElementsByTagName($tagname);

    Implements the DOM Level 2 function

  * getElementsByTagNameNS

        my LibXML::Element @nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);
        my LibXML::Node::Set $nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);

    Implements the DOM Level 2 function

  * getElementsByLocalName

        my LibXML::Element @nodes = $doc.getElementsByLocalName($localname);
        my LibXML::Node::Set $nodes = $doc.getElementsByLocalName($localname);

    This allows the fetching of all nodes from a given document with the given Localname.

  * getElementById

        my $node = $doc.getElementById($id);

    Returns the element that has an ID attribute with the given value. If no such element exists, this returns undef.

    Note: the ID of an element may change while manipulating the document. For documents with a DTD, the information about ID attributes is only available if DTD loading/validation has been requested. For HTML documents parsed with the HTML parser ID detection is done automatically. In XML documents, all "xml:id" attributes are considered to be of type ID. You can test ID-ness of an attribute node with $attr.isId().

    In versions 1.59 and earlier this method was called getElementsById() (plural) by mistake. Starting from 1.60 this name is maintained as an alias only for backward compatibility.

  * indexElements

        $dom.indexElements();

    This function causes libxml2 to stamp all elements in a document with their document position index which considerably speeds up XPath queries for large documents. It should only be used with static documents that won't be further changed by any DOM methods, because once a document is indexed, XPath will always prefer the index to other methods of determining the document order of nodes. XPath could therefore return improperly ordered node-lists when applied on a document that has been changed after being indexed. It is of course possible to use this method to re-index a modified document before using it with XPath again. This function is not a part of the DOM specification.

    This function returns number of elements indexed, -1 if error occurred, or -2 if this feature is not available in the running libxml2.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas

VERSION
=======

2.0132

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

