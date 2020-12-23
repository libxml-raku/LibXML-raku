[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Node](https://libxml-raku.github.io/LibXML-raku/Node)

class LibXML::Node
------------------

Abstract base class of LibXML Nodes

Synopsis
--------

    use LibXML::Node;
    my LibXML::Node $node;

    # -- Property Methods -- #
    my Str $name = $node.nodeName;
    $node.nodeName = $newName;
    my Bool $same = $node.isSameNode( $other-node );
    my Bool $blank = $node.isBlaNK;
    my Str $key = $node.unique-key;
    my Str $content = $node.nodeValue;
    $content = $node.textContent;
    my UInt $type = $node.nodeType;
    my Str $uri = $node.getBaseURI();
    $node.setBaseURI($uri);
    my Str $path = $node.nodePath();
    my UInt $lineno = $node.line-number();

    # -- Navigation Methods -- #
    $parent = $node.parentNode;
    my LibXML::Node $next = $node.nextSibling();
    $next = $node.nextNonBlankSibling();
    my LibXML::Node $prev = $node.previousSibling();
    $prev = $node.previousNonBlankSibling();
    my Bool $is-parent = $node.hasChildNodes();
    $child = $node.firstChild;
    $child = $node.lastChild;
    $other-node = $node.getOwner;
    my LibXML::Node @kids = $node.childNodes();
    @kids = $node.nonBlankChildNodes();

    # -- DOM Manipulation Methods -- #
    $node.unbindNode();
    $node.doc = $doc; # -OR- $node.setOwnerDoc($doc);
    my LibXML::Node $child = $node.removeChild( $node );
    $oldNode = $node.replaceChild( $newNode, $oldNode );
    $childNode = $node.appendChild( $childNode );
    $node = $parent.addNewChild( $nsURI, $name );
    $node.replaceNode($newNode);
    $node.addSibling($newNode);
    $newnode = $node.cloneNode( :deep );
    $node.insertBefore( $newNode, $refNode );
    $node.insertAfter( $newNode, $refNode );
    $node.removeChildNodes();
    $node.ownerDocument = $doc;

    # -- Searching Methods -- #
    #    * XPath *
    my LibXML::Node @found = $node.findnodes( $xpath-expr, :%ns );
    my LibXML::Node::Set $results = $node.find( $xpath-expr, :%ns );
    print $node.findvalue( $xpath-expr, :%ns );
    my Bool $found = $node.exists( $xpath-expr, :%ns );
    $found = $xpath-expression ~~ $node;
    my LibXML::Node $item = $node.first( $xpath-expr, :%ns );
    $item = $node.last( $xpath-expr, :%ns );
    #    * CSS selectors *
    $node.query-handler = CSS::Selector::To::XPath.new; # setup a query selector handler
    $item = $node.querySelector($css-selector); # first match
    $results = $node.querySelectorAll($css-selector); # all matches

    # -- Serialization Methods -- #
    my Str $xml = $node.Str(:format);
    my Str $xml-c14 = $node.Str: :C14N;
    $xml-c14 = $node.Str: :C14N, :comments, :xpath($expression), :exclusive;
    $xml-c14 = $node.Str :C14N, :v1_1, :xpath($expression);
    $xml = $doc.serialize(:format);
    # -- Binary serialization/encoding
    my blob8 $buf = $node.Blob(:format, :enc<UTF-8>);
    # -- Data  serialization -- #
    use LibXML::Item :ast-to-xml;
    my $node-data = $node.ast;
    my LibXML::Node $node2 = ast-to-xml($node-data);

    # -- Namespace Methods -- #
    my LibXML::Namespace @ns = $node.getNamespaces;
    my Str $localname = $node.localname;
    my Str $prefix = $node.prefix;
    my Str $uri = $node.namespaceURI();
    $uri = $node.lookupNamespaceURI( $prefix );
    $prefix = $node.lookupNamespacePrefix( $URI );
    $node.normalize;

    # -- Positional interface -- #
    $node.push: LibXML::Element.new: :name<A>;
    $node.push: LibXML::Element.new: :name<B>;
    say $node[1].Str; # <B/>
    $node[1] = LibXML::Element.new: :name<C>;
    say $node.values.map(*.Str).join(':');  # <A/>:<C/>
    $node.pop;  # remove last child

    # -- Associative interface -- #
    say $node.keys; # A B text() ..
    for $node<A> { ... }; # all '<A>..</A>' child nodes
    for $node<text()> { ... }; # text nodes

Description
-----------

LibXML::Node defines functions that are common to all Node Types. An LibXML::Node should never be created standalone, but as an instance of a high level class such as [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) or [LibXML::Text](https://libxml-raku.github.io/LibXML-raku/Text). The class itself should provide only common functionality. In LibXML each node is part either of a document or a document-fragment. Because of this there is no node without a parent.

Many methods listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/](http://www.w3.org/TR/DOM-Level-3-Core/)). Please refer to the specification for extensive documentation.

Property Methods
----------------

### method nodeName

```perl6
method nodeName() returns Str
```

Gets or sets the node name

This method is aware of namespaces and returns the full name of the current node (`prefix:localname`). 

It also returns the correct DOM names for node types with constant names, namely: `#text`, `#cdata-section`, `#comment`, `#document`, `#document-fragment`.

### method setNodeName

    method setNodeName(QName $new-name)
    # -Or-
    $.nodeName = $new-name

In very limited situations, it is useful to change a nodes name. In the DOM specification this should throw an error. This Function is aware of namespaces.

### method unique-key

    method unique-key() returns Str

This function is not specified for any DOM level. It returns a key guaranteed to be unique for this node, and to always be the same value for this node. In other words, two node objects return the same key if and only if isSameNode indicates that they are the same node.

The returned key value is useful as a key in hashes.

### method nodePath

    method nodePath() returns Str

This function is not specified for any DOM level: It returns a canonical structure based XPath for a given node.

### method isBlank

    method isBlank() returns Bool

True if this is a text node or processing instruction, and it contains only blank content

### method isSameNode

```perl6
method isSameNode(
    LibXML::Item $other
) returns Bool
```

True if both objects refer to the same native structure

### method nodeValue

```perl6
method nodeValue() returns Str
```

Get or set the value of a node

If the node has any content (such as stored in a `text node`) it can get requested through this function.

*NOTE:* Element Nodes have no content per definition. To get the text value of an element use textContent() instead!

### method textContent

```perl6
method textContent() returns Str
```

this function returns the content of all text nodes in the descendants of the given node as specified in DOM.

### method nodeType

```perl6
method nodeType() returns UInt
```

Return a numeric value representing the node type of this node.

The module [LibXML::Enums](https://libxml-raku.github.io/LibXML-raku/Enums) by default exports enumerated constants `XML_*_NODE` and `XML_*_DECL` for the node and declaration types.

### method getBaseURI

```perl6
method getBaseURI() returns Str
```

Gets the base URI

Searches for the base URL of the node. The method should work on both XML and HTML documents even if base mechanisms for these are completely different. It returns the base as defined in RFC 2396 sections "5.1.1. Base URI within Document Content" and "5.1.2. Base URI from the Encapsulating Entity". However it does not return the document base (5.1.3), use method `URI` of [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) for this. 

### method setBaseURI

```perl6
method setBaseURI(
    Str $uri
) returns Mu
```

Sets the base URI

This method only does something useful for an element node in an XML document. It sets the xml:base attribute on the node to $strURI, which effectively sets the base URI of the node to the same value. 

Note: For HTML documents this behaves as if the document was XML which may not be desired, since it does not effectively set the base URI of the node. See RFC 2396 appendix D for an example of how base URI can be specified in HTML. 

### method line-number

```perl6
method line-number() returns UInt
```

Return the source line number where the tag was found

If a node is added to the document the line number is 0. Problems may occur, if a node from one document is passed to another one.

IMPORTANT: Due to limitations in the libxml2 library line numbers greater than 65535 will be returned as 65535. Please see [http://bugzilla.gnome.org/show_bug.cgi?id=325533](http://bugzilla.gnome.org/show_bug.cgi?id=325533) for more details. 

Note: line-number() is special to LibXML and not part of the DOM specification.

Navigation Methods
------------------

### method parent

```perl6
method parent() returns LibXML::Node
```

Returns the objects parent node

### method nextSibling

```perl6
method nextSibling() returns LibXML::Node
```

Returns the next sibling if any.

### method nextNonBlankSibling

```perl6
method nextNonBlankSibling() returns LibXML::Node
```

Returns the next non-blank sibling if any.

A node is blank if it is a Text or CDATA node consisting of whitespace only. This method is not defined by DOM.

### method previousSibling

```perl6
method previousSibling() returns LibXML::Node
```

Analogous to getNextSibling(). Returns the previous sibling if any.

### method previousNonBlankSibling

```perl6
method previousNonBlankSibling() returns LibXML::Node
```

Returns the previous non-blank sibling, if any

A node is blank if it is a Text or CDATA node consisting of whitespace only. This method is not defined by DOM.

### method firstChild

```perl6
method firstChild() returns LibXML::Node
```

Return the first child node, if any

### method lastChild

```perl6
method lastChild() returns LibXML::Node
```

Return the last child node, if any

### hasChildNodes

```raku
method hasChildNodes() returns Bool
```

Returns True if the current node has child nodes, False otherwise.

### method appendText

```perl6
method appendText(
    Str:D $text
) returns Mu
```

Appends text directly to a node

Applicable to Element, Text, CData, Entity, EntityRef, PI, Comment, and DocumentFragment nodes.

ownerDocument

    method ownerDocument is rw returns LibXML::Document
    my LibXML::Document $doc = $node.ownerDocument;

Gets or sets the owner document for the node

### method setOwnerDocument

```perl6
method setOwnerDocument(
    LibXML::Node $doc
) returns Mu
```

Transfers a node to another document

This method unbinds the node first, if it is already bound to another document.

Calling `$node.setOwnerDocument($doc)` is equivalent to calling $doc.adoptNode($node)`. Because of this it has the same limitations with Entity References as adoptNode().

### method getOwner

```perl6
method getOwner() returns LibXML::Node
```

Get the root (owner) node

This function returns the root node that the current node is associated with. In most cases this will be a document node or a document fragment node.

### method childNodes

    method childNodes(Bool :$blank = True) returns LibXML::Node::List

Get child nodes of a node

*childNodes* implements a more intuitive interface to the childnodes of the current node. It enables you to pass all children directly to a `map` or `grep`.

Note that child nodes are iterable:

    for $elem.childNodes { ... }

They also directly support a number of update operations, including 'push' (add an element), 'pop' (remove last element) and ASSIGN-POS, e.g.:

    $elem.childNodes[3] = LibXML::TextNode.new('p', 'replacement text for 4th child');

### method nonBlankChildNodes

    method nonBlankChildNodes() returns LibXML::Node::List

Get non-blank child nodes of a node

This equivalent to *childNodes(:!blank)*. It returns only non-blank nodes (where a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

DOM Manipulation Methods
------------------------

### method unbindNode

```perl6
method unbindNode() returns LibXML::Node
```

Unbinds the Node from its siblings and Parent, but not from the Document it belongs to.

If the node is not inserted into the DOM afterwards, it will be lost after the program terminates.

### method removeChild

```perl6
method removeChild(
    LibXML::Node:D $node
) returns LibXML::Node
```

Unbind a child node from its parent

Fails if `$node` is not a child of this object

### method replaceChild

```perl6
method replaceChild(
    LibXML::Node $new,
    LibXML::Node $old
) returns LibXML::Node
```

Replaces the `$old` node with the `$new` node.

The returned `$old` node is unbound.

This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

### method appendChild

```perl6
method appendChild(
    LibXML::Item:D $new
) returns LibXML::Item
```

Adds a child to this nodes children (alias addChild)

Fails, if the new childnode is already a child of this node. This method differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

### method addNewChild

    method addNewChild(
        Str $uri,
        QName $name
    ) returns LibXML::Element

Vivify and add a new child element.

Similar to `addChild()`, this function uses low level libxml2 functionality to provide faster interface for DOM building. *addNewChild()* uses `xmlNewChild()` to create a new node on a given parent element.

addNewChild() has two parameters $nsURI and $name, where $nsURI is an (optional) namespace URI. $name is the fully qualified element name; addNewChild() will determine the correct prefix if necessary.

The function returns the newly created node.

This function is very useful for DOM building, where a created node can be directly associated with its parent. *NOTE* this function is not part of the DOM specification and its use may limit your code to Raku or Perl.

### method replaceNode

```perl6
method replaceNode(
    LibXML::Node:D $new
) returns LibXML::Node
```

Replace a node

This function is very similar to replaceChild(), but it replaces the node itself rather than a childnode. This is useful if a node found by any XPath function, should be replaced.

### method addSibling

```perl6
method addSibling(
    LibXML::Node:D $new
) returns LibXML::Node
```

Add an additional node to the end of a nodelist

### method cloneNode

```perl6
method cloneNode(
    Bool(Any) :$deep = Bool::False
) returns LibXML::Node
```

Copy a node

When $deep is True the function will copy all child nodes as well. Otherwise the current node will be copied. Note that in case of element, attributes are copied even if $deep is not True. 

### method insertBefore

```perl6
method insertBefore(
    LibXML::Node:D $new,
    LibXML::Node $ref?
) returns LibXML::Node
```

Inserts $new before $ref.

If `$ref` is undefined, the newNode will be set as the new last child of the parent node. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first, automatically.

Note, that the reference node has to be a direct child of the node the function is called on. Also, `$new` is not allowed to be an ancestor of the new parent node.

### method insertAfter

```perl6
method insertAfter(
    LibXML::Node:D $new,
    LibXML::Node $ref?
) returns LibXML::Node
```

Inserts $new after $ref.

If `$refNode` is undefined, the newNode will be set as the new last child of the parent node.

### method removeChildNodes

    method removeChildNodes() returns LibXML::DocumentFragment

Remove all child nodes, which are returned as a [LibXML::DocumentFragment](https://libxml-raku.github.io/LibXML-raku/DocumentFragment) This function is not specified for any DOM level: It removes all childnodes from a node in a single step.

Searching Methods
-----------------

### method findnodes

    multi method findnodes(Str $xpath-expr,
                           LibXML::Node $ref-node?,
                           Bool :$deref, :%ns) returns LibXML::Node::Set 
    multi method findnodes(LibXML::XPath::Expression:D $xpath-expr,
                           LibXML::Node $ref-node?,
                           Bool :$deref, :%ns) returns LibXML::Node::Set
    # Examples:
    my LibXML::Node @nodes = $node.findnodes( $xpath-expr );
    my LibXML::Node::Set $nodes = $node.findnodes( $xpath-expr, :deref );
    for $node.findnodes($xpath-expr) {...}

*findnodes* evaluates the XPath expression (XPath 1.0) on the current node and returns the resulting node set as an array; returning an [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) object.

The XPath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

The `:deref` option has an effect on associative indexing:

    my $humps = $node.findnodes("dromedaries/species")<species/humps>;
    my $humps = $node.findnodes("dromedaries/species", :deref)<humps>;

It indexes element child nodes and attributes. This option is used by the `AT-KEY` method (see below).

*NOTE ON NAMESPACES AND XPATH*:

A common mistake about XPath is to assume that node tests consisting of an element name with no prefix match elements in the default namespace. This assumption is wrong - by XPath specification, such node tests can only match elements that are in no (i.e. null) namespace. 

So, for example, one cannot match the root element of an XHTML document with `$node.find('/html')` since `'/html'` would only match if the root element `<html>` had no namespace, but all XHTML elements belong to the namespace http://www.w3.org/1999/xhtml. (Note that `xmlns="..."` namespace declarations can also be specified in a DTD, which makes the situation even worse, since the XML document looks as if there was no default namespace). 

There are several possible ways to deal with namespaces in XPath: 

  * The recommended way is to define a document independent prefix-to-namespace mapping. For example: 

        my %ns = 'x' => 'http://www.w3.org/1999/xhtml';
        $node.find('/x:html', :%ns);

    --OR--

        my $xpath-context = $node.xpath-context: :%ns;
        $xpath-context.find('/x:html');

  * Another possibility is to use prefixes declared in the queried document (if known). If the document declares a prefix for the namespace in question (and the context node is in the scope of the declaration), `LibXML` allows you to use the prefix in the XPath expression, e.g.: 

        $node.find('/xhtml:html');

### method find

    multi method find( Str $xpath, :%ns) returns Any
    multi method find( LibXML::XPath::Expression:D $xpath, :%ns) returns Any

*find* evaluates the XPath 1.0 expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath "1 * 3 + 52" results in a [Numeric](Numeric) object being returned. Other expressions might return an [Bool](Bool) object, or a [Str](Str) object.

The XPath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

See also [LibXML::XPathContext](https://libxml-raku.github.io/LibXML-raku/XPathContext).find.

### method findvalue

    multi method findvalue( Str $xpath, :%ns) returns Str
    multi method findvalue( LibXML::XPath::Expression:D $xpath, :%ns) returns Str

*findvalue* is equivalent to:

    $node.find( $xpath ).to-literal;

That is, it returns the literal value of the results. This enables you to ensure that you get a string back from your search, allowing certain shortcuts. This could be used as the equivalent of XSLT's <xsl:value-of select="some_xpath"/>.

See also [LibXML::XPathContext](https://libxml-raku.github.io/LibXML-raku/XPathContext).findvalue.

The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

### method first

    multi method first(Bool :$blank=True, :%ns) returns LibXML::Node
    multi method first(Str $xpath-expr, :%ns) returns LibXML::Node
    multi method first(LibXML::XPath::Expression:D $xpath-expr, :%ns) returns LibXML::Node
    # Examples
    my $child = $node.first;          # first child
    my $child = $node.first: :!blank; # first non-blank child
    my $descendant = $node.first($xpath-expr);

This node returns the first child node, or descendant node that matches an optional XPath expression.

### method last

    multi method last(Bool :$blank=True, :%ns) returns LibXML::Node
    multi method last(Str $xpath-expr, :%ns) returns LibXML::Node
    multi method last(LibXML::XPath::Expression:D $xpath-expr) returns LibXML::Node
    # Examples
    my $child = $node.last;          # last child
    my $child = $node.last: :!blank; # last non-blank child
    my $descendant = $node.last($xpath-expr);

This node returns the last child node, or descendant node that matches an optional XPath expression.

### method exists

    multi method exists(Str $xpath-expr, :%ns) returns Bool
    multi method exist(LibXML::XPath::Expression:D $xpath-expr, :%ns) returns Bool

This method behaves like *findnodes*, except that it only returns a boolean value (True if the expression matches a node, False otherwise) and may be faster than *findnodes*, because the XPath evaluation may stop early on the first match.

For XPath expressions that do not return node-set, the method returns True if the returned value is a non-zero number or a non-empty string.

### xpath-context

    method xpath-context() returns LibXML::XPath::Context

Gets the [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context) object that is used for xpath queries (including `find()`, `findvalue()`, `exists()` and some `AT-KEY` queries.

    $node.xpath-context.set-options: :suppress-warnings, :suppress-errors;

### methods query-handler, querySelector, querySelectorAll

These methods provide pluggable support for CSS (or other 3rd party) Query Selectors. See https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE. For example, to use the [CSS::Selector::To::XPath](CSS::Selector::To::XPath) (module available separately).

    use CSS::Selector::To::XPath;
    $doc.query-handler = CSS::Selector::To::XPath.new;
    my $result-query = "#score>tbody>tr>td:nth-of-type(2)"
    my $results = $doc.querySelectorAll($result-query);
    my $first-result = $doc.querySelector($result-query);

See [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context) for more details.

Serialization Methods
---------------------

### method canonicalize

```perl6
method canonicalize(
    Bool(Any) :$comments = Bool::False,
    Bool(Any) :$exclusive = Bool::False,
    Version :$v = v1.0,
    :$xpath is copy where { ... },
    :$selector = Code.new,
    :@prefix,
    Int :$mode where { ... } = Code.new
) returns Str
```

serialize to a string; canonicalized as per C14N specification

The canonicalize method is similar to Str(). Instead of simply serializing the document tree, it transforms it as it is specified in the XML-C14N Specification (see [http://www.w3.org/TR/xml-c14n](http://www.w3.org/TR/xml-c14n)). Such transformation is known as canonicalization.

If :$comments is False or not specified, the result-document will not contain any comments that exist in the original document. To include comments into the canonized document, :$comments has to be set to True.

The parameter :$xpath defines the nodeset of nodes that should be visible in the resulting document. This can be used to filter out some nodes. One has to note, that only the nodes that are part of the nodeset, will be included into the result-document. Their child-nodes will not exist in the resulting document, unless they are part of the nodeset defined by the xpath expression. 

If :$xpath is omitted or empty, Str: :C14N will include all nodes in the given sub-tree, using the following XPath expressions: with comments 

```xpath
(. | .//node() | .//@* | .//namespace::*)
```

and without comments 

```xpath
(. | .//node() | .//@* | .//namespace::*)[not(self::comment())]
```

An optional parameter :$selector can be used to pass an [LibXML::XPathContext](https://libxml-raku.github.io/LibXML-raku/XPathContext) object defining the context for evaluation of $xpath-expression. This is useful for mapping namespace prefixes used in the XPath expression to namespace URIs. Note, however, that $node will be used as the context node for the evaluation, not the context node of :$selector. 

:v(v1.1) can be passed to specify v1.1 of the C14N specification. The `:$eclusve` flag is not applicable to this level.

### multi method Str :C14N

    multi method Str(Bool :C14N!, *%opts) returns Str

`$node.Str( :C14N, |%opts)` is equivalent to `$node.canonicalize(|%opts)`

### multi method Str() returns Str

    method Str(Bool :$format, Bool :$tag-expansion) returns Str;

This method is similar to the method `Str` of a [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) but for a single node. It returns a string consisting of XML serialization of the given node and all its descendants.

### method serialize

    method serialize(*%opts) returns Str

An alias for Str. This function name was added to be more consistent with libxml2.

### method Blob() returns Blob

    method Blob(
        xmlEncodingStr :$enc = 'UTF-8',
        Bool :$format,
        Bool :$tag-expansion
    ) returns Blob;

Returns a binary representation of the XML node and its descendants encoded as `:$enc`.

### method ast

```perl6
method ast() returns Pair
```

Data serialization

This method performs a deep data-serialization of the node. The [LibXML::Item](https://libxml-raku.github.io/LibXML-raku/Item) ast-to-xml() function can then be used to create a deep copy of the node;

    use LibXML::Item :ast-to-xml;
    my $ast = $node.ast;
    my LibXML::Node $copy = ast-to-xml($ast);

Namespace Methods
-----------------

### method localname

```perl6
method localname() returns Str
```

Returns the local name of a tag.

This is the part after the colon.

### method prefix

```perl6
method prefix() returns Str
```

Returns the prefix of a tag

This is the part before the colon.

### method getNamespaces

    method getNamespaces returns LibXML::Node::List
    my LibXML::Namespace @ns = $node.getNamespaces;

If a node has any namespaces defined, this function will return these namespaces. Note, that this will not return all namespaces that are in scope, but only the ones declared explicitly for that node.

Although getNamespaces is available for all nodes, it only makes sense if used with element nodes.

### method namespaceURI

```perl6
method namespaceURI() returns Str
```

Returns the URI of the current namespace.

### method lookupNamespaceURI

    method lookupNamespaceURI( NCName $prefix ) returns Str;

Find a namespace URI by its prefix starting at the current node.

### method lookupNamespacePrefix

    method lookupNamespacePrefix( Str $URI ) returns NCName;

Find a namespace prefix by its URI starting at the current node.

*NOTE* Only the namespace URIs are meant to be unique. The prefix is only document related. Also the document might have more than a single prefix defined for a namespace.

### method normalize

    method normalize() returns Str

This function normalizes adjacent text nodes. This function is not as strict as libxml2's xmlTextMerge() function, since it will not free a node that is still referenced by Raku.

Associative Interface
---------------------

### methods AT-KEY, keys

    say $node.AT-KEY("species");
    #-OR-
    say $node<species>;

    say $node<species>.keys; # (disposition text() @name humps)
    say $node<species/humps>;
    say $node<species><humps>;

This is a lightweight associative interface, based on xpath expressions. `$node.AT-KEY($foo)` is equivalent to `$node.findnodes($foo, :deref)`. 

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

