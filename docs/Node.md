NAME
====

LibXML::Node - Abstract Base Class of LibXML Nodes

SYNOPSIS
========

```raku
use LibXML::Node;
my LibXML::Node $node;

# -- Basic Properties -- #
my Str $name = $node.nodeName;
$node.nodeName = $newName;
my Bool $same = $node.isSame( $other-node );
my Str $key = $node.unique-key;
my Str $content = $node.nodeValue;
$content = $node.textContent;
my UInt $type = $node.nodeType;
$uri = $node.baseURI();
$node.baseURI = $uri;
$node.nodePath();
my UInt $lineno = $node.line-number();

# -- DOM Manipulation -- #
$node.unbindNode();
my LibXML::Node $child = $node.removeChild( $node );
$oldNode = $node.replaceChild( $newNode, $oldNode );
$node.replaceNode($newNode);
$childNode = $node.appendChild( $childNode );
$childNode = $node.addChild( $childNode );
$node = $parent.addNewChild( $nsURI, $name );
$node.addSibling($newNode);
$newnode = $node.cloneNode( :deep );
$node.insertBefore( $newNode, $refNode );
$node.insertAfter( $newNode, $refNode );
$node.removeChildNodes();

# -- Navigation -- #
$parent = $node.parentNode;
my LibXML::Node $next = $node.nextSibling();
$next = $node.nextNonBlankSibling();
my LibXML::Node $prev = $node.previousSibling();
$prev = $node.previousNonBlankSibling();
my Bool $is-parent = $node.hasChildNodes();
$child = $node.firstChild;
$child = $node.lastChild;
my LibXML::Document $doc = $node.ownerDocument;
$doc = $node.getOwner;
$node.ownerDocument = $doc;
my LibXML::Node @kids = $node.childNodes();
@kids = $node.nonBlankChildNodes();

# -- Searching -- #
#    * XPath *
my LibXML::Node @found = $node.findnodes( $xpath-expression );
my LibXML::Node::Set $results = $node.find( $xpath-expression );
print $node.findvalue( $xpath-expression );
my Bool $found = $node.exists( $xpath-expression );
$found = $xpath-expression ~~ $node;
my LibXML::Node $item = $node.first( $xpath-expression );
$item = $node.last( $xpath-expression );
#    * CSS selectors *
$node.query-handler = CSS::Selector::To::XPath.new; # setup a query selector handler
$item = $node.querySelector($css-selector); # first match
$results = $node.querySelectorAll($css-selector); # all matches

# -- String serialization -- #
my Str $xml = $node.Str(:format);
my Str $xml-c14 = $node.Str: :C14N;
$xml-c14 = $node.Str: :C14N, :comments, :xpath($expression), :exclusive;
$xml-c14 = $node.Str: :C14N, :v1_1;
$xml-c14 = $node.Str :C14N, :v1_1, :xpath($expression), :exclusive;
$xml = $doc.serialize(:format);
# -- Binary serialization/encoding
my blob8 $buf = $node.Blob(:format, :enc<UTF-8>);
# -- Data  serialization -- #
use LibXML::Item :ast-to-xml;
my $node-data = $node.ast;
my LibXML::Node $node2 = ast-to-xml($node-data);

# -- Namespaces -- #
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

# -- Associative/XPath interface -- #
say $node.keys; # A B text() ..
for $node<A> { ... }; # all '<A>..</A>' child nodes
for $node<text()> { ... }; # text nodes
```

DESCRIPTION
===========

LibXML::Node defines functions that are common to all Node Types. An LibXML::Node should never be created standalone, but as an instance of a high level class such as [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) or [LibXML::Text](https://libxml-raku.github.io/LibXML-raku/Text). The class itself should provide only common functionality. In LibXML each node is part either of a document or a document-fragment. Because of this there is no node without a parent.

METHODS
=======

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/ ](http://www.w3.org/TR/DOM-Level-3-Core/ )). Please refer to the specification for extensive documentation. 

  * nodeName

    ```raku
    my Str $name = $node.nodeName;
    ```

    Returns the node's name. This function is aware of namespaces and returns the full name of the current node (`prefix:localname `). 

    This function also returns the correct DOM names for node types with constant names, namely: #text, #cdata-section, #comment, #document, #document-fragment.

  * setNodeName

    ```raku
    $node.setNodeName( $newName );
    $node.nodeName = $newName;
    ```

    In very limited situations, it is useful to change a nodes name. In the DOM specification this should throw an error. This Function is aware of namespaces.

  * isSameNode

    ```raku
    my Bool $is-same = $node.isSameNode( $other_node );
    ```

    returns True if the given nodes refer to the same node structure, otherwise False is returned.

  * unique-key

    ```raku
    my Str $key = $node.unique-key;
    ```

    This function is not specified for any DOM level. It returns a key guaranteed to be unique for this node, and to always be the same value for this node. In other words, two node objects return the same key if and only if isSameNode indicates that they are the same node.

    The returned key value is useful as a key in hashes.

  * nodeValue

    ```raku
    my Str $content = $node.nodeValue;
    ```

    If the node has any content (such as stored in a `text node `) it can get requested through this function.

    *NOTE: * Element Nodes have no content per definition. To get the text value of an Element use textContent() instead!

  * textContent

    ```raku
    my Str $content = $node.textContent;
    ```

    this function returns the content of all text nodes in the descendants of the given node as specified in DOM.

  * nodeType

    ```raku
    my UInt $type = $node.nodeType;
    ```

    Return a numeric value representing the node type of this node. The module LibXML by default exports constants for the node types (see the EXPORT section in the [LibXML ](https://libxml-raku.github.io/LibXML-raku) manual page).

  * unbindNode

    ```raku
    $node.unbindNode();
    ```

    Unbinds the Node from its siblings and Parent, but not from the Document it belongs to. If the node is not inserted into the DOM afterwards, it will be lost after the program terminates. From a low level view, the unbound node is stripped from the context it is and inserted into a (hidden) document-fragment.

  * removeChild

    ```raku
    my LibXML::Node $child = $node.removeChild( $node );
    ```

    This will unbind the Child Node from its parent `$node `. The function returns the unbound node. If `oldNode ` is not a child of the given Node the function will fail.

  * replaceChild

    ```raku
    $oldnode = $node.replaceChild( $newNode, $oldNode );
    ```

    Replaces the `$oldNode ` with the `$newNode `. The `$oldNode ` will be unbound from the Node. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

  * replaceNode

    ```raku
    $node.replaceNode($newNode);
    ```

    This function is very similar to replaceChild(), but it replaces the node itself rather than a childnode. This is useful if a node found by any XPath function, should be replaced.

  * appendChild

    ```raku
    $childnode = $node.appendChild( $childnode );
    ```

    The function will add the `$childnode ` to the end of `$node `'s children. The function should fail, if the new childnode is already a child of `$node `. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

  * addChild

    ```raku
    $childnode = $node.addChild( $childnode );
    ```

    This is alias for appendChild (unlike Perl 5 which binds this to xmlAddChild()).

  * addNewChild

    ```raku
    $node = $parent.addNewChild( $nsURI, $name );
    ```

    Similar to `addChild() `, this function uses low level libxml2 functionality to provide faster interface for DOM building. *addNewChild() * uses `xmlNewChild() ` to create a new node on a given parent element.

    addNewChild() has two parameters $nsURI and $name, where $nsURI is an (optional) namespace URI. $name is the fully qualified element name; addNewChild() will determine the correct prefix if necessary.

    The function returns the newly created node.

    This function is very useful for DOM building, where a created node can be directly associated with its parent. *NOTE * this function is not part of the DOM specification and its use will limit your code to LibXML.

  * addSibling

    ```raku
    $node.addSibling($newNode);
    ```

    addSibling() allows adding an additional node to the end of a nodelist, defined by the given node.

  * cloneNode

    ```raku
    $newnode = $node.cloneNode( :$deep );
    ```

    *cloneNode * creates a copy of `$node `. When $deep is True the function will copy all child nodes as well. Otherwise the current node will be copied. Note that in case of element, attributes are copied even if $deep is not True. 

    Note that the behavior of this function for $deep=0 has changed in 1.62 in order to be consistent with the DOM spec (in older versions attributes and namespace information was not copied for elements).

  * ast

    This method performs a deep data-serialization of the node. The [LibXML::Item](https://libxml-raku.github.io/LibXML-raku/Item) ast-to-xml() function can then be used to create a deep copy of the node;

    ```raku
      use LibXML::Item :ast-to-xml;
      my $ast = $node.ast;
      my LibXML::Node $copy = ast-to-xml($ast);
    ```

  * parentNode

    ```raku
    my LibXML::Node $parent = $node.parentNode;
    ```

    Returns simply the Parent Node of the current node.

  * nextSibling

    ```raku
    my LibXML::Node $next = $node.nextSibling();
    ```

    Returns the next sibling if any .

  * nextNonBlankSibling

    ```raku
    my LibXML::Node $next = $node.nextNonBlankSibling();
    ```

    Returns the next non-blank sibling if any (a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * previousSibling

    ```raku
    my LibXML::Node $prev = $node.previousSibling();
    ```

    Analogous to *getNextSibling * the function returns the previous sibling if any.

  * previousNonBlankSibling

    ```raku
    my LibXML::Node $prev = $node.previousNonBlankSibling();
    ```

    Returns the previous non-blank sibling if any (a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * hasChildNodes

    ```raku
    my Bool $has-kids = $node.hasChildNodes();
    ```

    If the current node has child nodes this function returns True, otherwise it returns False.

  * firstChild

    ```raku
    my LibXML::Node $child = $node.firstChild;
    ```

    If a node has child nodes this function will return the first node in the child list.

  * lastChild

    ```raku
    my LibXML::Node $child = $node.lastChild;
    ```

    If the `$node ` has child nodes this function returns the last child node.

  * ownerDocument

    ```raku
    my LibXML::Document $doc = $node.ownerDocument;
    ```

    Through this function it is always possible to access the document the current node is bound to.

  * getOwner

    ```raku
    my LibXML::Node $owner = $node.getOwner;
    ```

    This function returns the node the current node is associated with. In most cases this will be a document node or a document fragment node.

  * setOwnerDocument

    ```raku
    $node.setOwnerDocument( $doc );
    $node.ownerDocument = doc;
    ```

    This function binds a node to another DOM. This method unbinds the node first, if it is already bound to another document.

    This function is the opposite calling of [LibXML::Document ](https://libxml-raku.github.io/LibXML-raku/Document)'s adoptNode() function. Because of this it has the same limitations with Entity References as adoptNode().

  * insertBefore

    ```raku
    $node.insertBefore( $newNode, $refNode );
    ```

    The method inserts `$newNode ` before `$refNode `. If `$refNode ` is undefined, the newNode will be set as the new last child of the parent node. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first, automatically.

    Note, that the reference node has to be a direct child of the node the function is called on. Also, $newChild is not allowed to be an ancestor of the new parent node.

  * insertAfter

    ```raku
    $node.insertAfter( $newNode, $refNode );
    ```

    The method inserts `$newNode ` after `$refNode `. If `$refNode ` is undefined, the newNode will be set as the new last child of the parent node.

  * findnodes

    ```raku
    my LibXML::Node @nodes = $node.findnodes( $xpath-expression );
    my LibXML::Node::Set $nodes = $node.findnodes( $xpath-expression, :deref );
    ```

    *findnodes * evaluates the xpath expression (XPath 1.0) on the current node and returns the resulting node set as an array. In item context, returns an [LibXML::Node::Set ](https://libxml-raku.github.io/LibXML-raku/Node/Set) object.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

    The `:deref` option has an effect on associatve indexing:

    ```raku
    my $humps = $node.findnodes("dromedaries/species")<species/humps>;
    my $humps = $node.findnodes("dromedaries/species", :deref)<humps>;
    ```

    It indexes element child nodes and attributes. This option is used by the `AT-KEY` method (see below).

    *NOTE ON NAMESPACES AND XPATH *:

    A common mistake about XPath is to assume that node tests consisting of an element name with no prefix match elements in the default namespace. This assumption is wrong - by XPath specification, such node tests can only match elements that are in no (i.e. null) namespace. 

    So, for example, one cannot match the root element of an XHTML document with `$node-&gt;find('/html') ` since `'/html' ` would only match if the root element `&lt;html&gt; ` had no namespace, but all XHTML elements belong to the namespace http://www.w3.org/1999/xhtml. (Note that `xmlns="..." ` namespace declarations can also be specified in a DTD, which makes the situation even worse, since the XML document looks as if there was no default namespace). 

    There are several possible ways to deal with namespaces in XPath: 

      * The recommended way is to use the [LibXML::XPathContext ](https://libxml-raku.github.io/LibXML-raku/XPathContext) module to define an explicit context for XPath evaluation, in which a document independent prefix-to-namespace mapping can be defined. For example: 

        ```raku
        my $xpc = LibXML::XPathContext.new;
        $xpc.registerNs('x', 'http://www.w3.org/1999/xhtml');
        $xpc.find('/x:html', $node);
        ```

      * Another possibility is to use prefixes declared in the queried document (if known). If the document declares a prefix for the namespace in question (and the context node is in the scope of the declaration), `LibXML ` allows you to use the prefix in the XPath expression, e.g.: 

        ```raku
        $node.find('/x:html');
        ```

    See also LibXML::XPathContext.findnodes.

  * first, last

    ```raku
      my LibXML::Node $body = $doc.first('body');
      my LibXML::Node $last-row = $body.last('descendant::tr');
    ```

    The `first` and `last` methods are similar to `findnodes`, except they return a single node representing the first or last matching row. If no nodes were found, `LibXML::Node:U` is returned.

  * query-handler, querySelector, querySelectorAll

    These methods provide pluggable support for CSS (or other 3rd party) Query Selectors. See https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE. For example, to use the [CSS::Selector::To::XPath](CSS::Selector::To::XPath) (module available separately).

    ```raku
    use CSS::Selector::To::XPath;
    $doc.query-handler = CSS::Selector::To::XPath.new;
    my $result-query = "#score>tbody>tr>td:nth-of-type(2)"
    my $results = $doc.querySelectorAll($result-query);
    my $first-result = $doc.querySelector($result-query);
    ```

    See [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context) for more details.

  * AT-KEY, keys

    ```raku
    say $node.AT-KEY("species");
    #-OR-
    say $node<species>;

    say $node<species>.keys; # (disposition text() @name humps)
    say $node<species/humps>;
    say $node<species><humps>;
    ```

    This is a lightweight associative interface, based on xpath expressions. `$node.AT-KEY($foo)` is equivalent to `$node.findnodes($foo, :deref)`. 

  * find

    ```raku
    $result = $node.find( $xpath );
    ```

    *find * evaluates the XPath 1.0 expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath "1 * 3 + 52" results in a [Numeric ](Numeric ) object being returned. Other expressions might return an [Bool ](Bool ) object, or a [Str ](Str ) object.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

    See also [LibXML::XPathContext ](https://libxml-raku.github.io/LibXML-raku/XPathContext).find.

  * findvalue

    ```raku
    print $node.findvalue( $xpath );
    ```

    *findvalue * is equivalent to:

    ```raku
    $node.find( $xpath ).to-literal;
    ```

    That is, it returns the literal value of the results. This enables you to ensure that you get a string back from your search, allowing certain shortcuts. This could be used as the equivalent of XSLT's <xsl:value-of select="some_xpath"/>.

    See also [LibXML::XPathContext ](https://libxml-raku.github.io/LibXML-raku/XPathContext).findvalue.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

  * first

    ```raku
      my $child = $node.first;          # first child
      my $child = $node.first, :!blank; # first non-blank child
      my $descendant = $node.first($xpath-expr);
    ```

    This node returns the first child node, or descendant node that matches an optional XPath expression.

  * last

    ```raku
      my $child = $node.last;          # last child
      my $descendant = $node.last($xpath-expr);
    ```

    This node returns the last child, or descendant node that matches an optional XPath expression.

  * exists

    ```raku
    my Bool $found = $node.exists( $xpath_expression );
    ```

    This method behaves like *findnodes *, except that it only returns a boolean value (True if the expression matches a node, False otherwise) and may be faster than *findnodes *, because the XPath evaluation may stop early on the first match.

    For XPath expressions that do not return node-set, the method returns true if the returned value is a non-zero number or a non-empty string.

  * xpath-context

    Gets the [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context) object that is used for xpath queries (including `find()`, `findvalue()`, `exists()` and some `AT-KEY` queries.

    ```raku
    $node.xpath-context.set-options: :suppress-warnings, :suppress-errors;
    ```

  * childNodes (handles: elems List values map grep push pop)

    ```raku
    my LibXML::Node @kids = $node.childNodes();
    my LibXML::Node::List $kids = $node.childNodes();
    ```

    *childNodes * implements a more intuitive interface to the childnodes of the current node. It enables you to pass all children directly to a `map ` or `grep `.

    Note that child nodes are iterable:

    ```raku
     for $elem.childNodes { ... }
    ```

    They also directly support a number of update operations, including 'push' (add an element), 'pop' (remove last element) and ASSIGN-POS, e.g.:

    ```raku
     $elem.childNodes[3] = LibXML::TextNode.new('p', 'replacement text for 4th child');
    ```

  * nonBlankChildNodes

    ```raku
    my LibXML::Node @kids = $node.nonBlankChildNodes();
    my LibXML::Node::List $kids = $node.nonBlankChildNodes();
    ```

    This is like *childNodes *, but returns only non-blank nodes (where a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * Str

    ```raku
    my Str $xml = $node.Str(:format);
    ```

    This method is similar to the method `Str ` of a [LibXML::Document ](https://libxml-raku.github.io/LibXML-raku/Document) but for a single node. It returns a string consisting of XML serialization of the given node and all its descendants. Unlike `LibXML::Document::Str `.

  * Str: :C14N

    ```raku
    my Str $xml-c14 = $node.Str: :C14N;
    $c14nstring = $node.String, :C14N, :comments, :xpath($xpath-expression);
    ```

    The function is similar to Str(). Instead of simply serializing the document tree, it transforms it as it is specified in the XML-C14N Specification (see [http://www.w3.org/TR/xml-c14n ](http://www.w3.org/TR/xml-c14n )). Such transformation is known as canonization.

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

    An optional parameter :$selector can be used to pass an [LibXML::XPathContext ](https://libxml-raku.github.io/LibXML-raku/XPathContext) object defining the context for evaluation of $xpath-expression. This is useful for mapping namespace prefixes used in the XPath expression to namespace URIs. Note, however, that $node will be used as the context node for the evaluation, not the context node of :$selector. 

  * Str: :C14N, :v(v1.1)

    ```raku
    $c14nstring = $node.Str: :C14N, :v(v1.1);
    $c14nstring = $node.String: :C14N, :v(v1.1), :comments, :xpath($expression) , :selector($context);
    ```

    This function behaves like Str: :C14N except that it uses the "XML_C14N_1_1" constant for canonicalising using the "C14N 1.1 spec". 

  * Str: :C14N, :exclusive

    ```raku
    $ec14nstring = $node.Str: :C14N, :exclusive;
    $ec14nstring = $node.Str: :C14N, :exclusive, :$comments, :xpath($expression), :prefix(@inclusive-list);
    ```

    The function is similar to Str: :C14N but follows the XML-EXC-C14N Specification (see [http://www.w3.org/TR/xml-exc-c14n ](http://www.w3.org/TR/xml-exc-c14n )) for exclusive canonization of XML.

    The arguments :comments, :$xpath, :$selector are as in Str: :C14N. :@prefix is a list of namespace prefixes that are to be handled in the manner described by the Canonical XML Recommendation (i.e. preserved in the output even if the namespace is not used). C.f. the spec for details. 

  * serialize

    ```raku
    my Str $xml = $doc.serialize($format);
    ```

    An alias for Str. This function was name added to be more consistent with libxml2.

  * serialize-c14n

    An alias for Str: :C14N.

  * serialize-exc-c14n

    An alias for Str: :C14N, :exclusive

  * localname

    ```raku
    my Str $localname = $node.localname;
    ```

    Returns the local name of a tag. This is the part behind the colon.

  * prefix

    ```raku
    my Str $prefix = $node.prefix;
    ```

    Returns the prefix of a tag. This is the part before the colon.

  * namespaceURI

    ```raku
    my Str $uri = $node.namespaceURI();
    ```

    returns the URI of the current namespace.

  * lookupNamespaceURI

    ```raku
    $URI = $node.lookupNamespaceURI( $prefix );
    ```

    Find a namespace URI by its prefix starting at the current node.

  * lookupNamespacePrefix

    ```raku
    $prefix = $node.lookupNamespacePrefix( $URI );
    ```

    Find a namespace prefix by its URI starting at the current node.

    *NOTE * Only the namespace URIs are meant to be unique. The prefix is only document related. Also the document might have more than a single prefix defined for a namespace.

  * normalize

    ```raku
    $node.normalize;
    ```

    This function normalizes adjacent text nodes. This function is not as strict as libxml2's xmlTextMerge() function, since it will not free a node that is still referenced by Raku.

  * getNamespaces

    ```raku
    my LibXML::Namespace @ns = $node.getNamespaces;
    ```

    If a node has any namespaces defined, this function will return these namespaces. Note, that this will not return all namespaces that are in scope, but only the ones declared explicitly for that node.

    Although getNamespaces is available for all nodes, it only makes sense if used with element nodes.

  * removeChildNodes

    ```raku
    $node.removeChildNodes();
    ```

    This function is not specified for any DOM level: It removes all childnodes from a node in a single step. Other than the libxml2 function itself (xmlFreeNodeList), this function will not immediately remove the nodes from the memory. This saves one from getting memory violations, if there are nodes still referred to from Raku.

  * baseURI ()

    ```raku
    my Str $URI = $node.baseURI();
    ```

    Searches for the base URL of the node. The method should work on both XML and HTML documents even if base mechanisms for these are completely different. It returns the base as defined in RFC 2396 sections "5.1.1. Base URI within Document Content" and "5.1.2. Base URI from the Encapsulating Entity". However it does not return the document base (5.1.3), use method `URI ` of `LibXML::Document ` for this. 

  * setBaseURI ($URI)

    ```raku
    $node.setBaseURI($URI);
    $node.baseURI = $URI;
    ```

    This method only does something useful for an element node in an XML document. It sets the xml:base attribute on the node to $strURI, which effectively sets the base URI of the node to the same value. 

    Note: For HTML documents this behaves as if the document was XML which may not be desired, since it does not effectively set the base URI of the node. See RFC 2396 appendix D for an example of how base URI can be specified in HTML. 

  * nodePath

    ```raku
    my Str $path = $node.nodePath();
    ```

    This function is not specified for any DOM level: It returns a canonical structure based XPath for a given node.

  * line-number

    ```raku
    my Uint $lineno = $node.line-number();
    ```

    This function returns the line number where the tag was found during parsing. If a node is added to the document the line number is 0. Problems may occur, if a node from one document is passed to another one.

    IMPORTANT: Due to limitations in the libxml2 library line numbers greater than 65535 will be returned as 65535. Please see [http://bugzilla.gnome.org/show_bug.cgi?id=325533 ](http://bugzilla.gnome.org/show_bug.cgi?id=325533 ) for more details. 

    Note: line-number() is special to LibXML and not part of the DOM specification.

    If the line-numbers flag of the parser was not activated before parsing, line-number() will always return 0.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

