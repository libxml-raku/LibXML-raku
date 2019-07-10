NAME
====

LibXML::Node - Abstract Base Class of LibXML Nodes

SYNOPSIS
========

    use LibXML::Node;

    my Str $name = $node.nodeName;
    $node.nodeName = $newName;
    my Bool $same = $node.isSameNode( $other_node );
    my Str $key = $node.unique-key;
    my Str $content = $node.nodeValue;
    $content = $node.textContent;
    my UInt $type = $node.nodeType;
    $node.unbindNode();
    my LibXML::Node $child = $node.removeChild( $node );
    $oldNode = $node.replaceChild( $newNode, $oldNode );
    $node.replaceNode($newNode);
    $childNode = $node.appendChild( $childNode );
    $childNode = $node.addChild( $childNode );
    $node = $parent.addNewChild( $nsURI, $name );
    $node.addSibling($newNode);
    $newnode = $node.cloneNode( :deep );
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
    $node.insertBefore( $newNode, $refNode );
    $node.insertAfter( $newNode, $refNode );
    @nodes = $node.findnodes( $xpath-expression );
    my LibXML::Node::Set $result = $node.find( $xpath-expression );
    print $node.findvalue( $xpath-expression );
    my Bool $found = $node.exists( $xpath-expression );
    my LibXML::Node @kids = $node.childNodes();
    @kids = $node.nonBlankChildNodes();
    my Str $xml = $node.Str(:format, :$enc);
    my Str $xml-c14 = $node.Str: :C14N;
    $xml-c14 = $node.Str: :C14N, :comments, :xpath($expression), :exclusive;
    $xml-c14 = $node.Str: :C14N, :v1_1;
    $xml-c14 = $node.Str :C14N, :v1_1, :xpath($expression), :exclusive;
    $xml = $doc.serialize(:format); 
    my Str $localname = $node.localname;
    my Str $prefix = $node.prefix;
    my Str $uri = $node.namespaceURI();
    $uri = $node.lookupNamespaceURI( $prefix );
    $prefix = $node.lookupNamespacePrefix( $URI );
    $node.normalize;
    my LibXML::Namespace @ns = $node.getNamespaces;
    $node.removeChildNodes();
    $uri = $node.baseURI();
    $node.baseURI = $uri;
    $node.nodePath();
    my UInt $lineno = $node.line-number();

    # Positional interface (on child nodes)
    $node.push: LibXML::Element.new: :name<A>;
    $node.push: LibXML::Element.new: :name<B>;
    say $node[1].Str; # <B/>
    $node[1] = LibXML::Element.new: :name<C>;
    say $node.values.map(*.Str).join(':');  # <A/>:<C/>
    $node.pop;

DESCRIPTION
===========

LibXML::Node defines functions that are common to all Node Types. An LibXML::Node should never be created standalone, but as an instance of a high level class such as LibXML::Element or LibXML::Text. The class itself should provide only common functionality. In LibXML each node is part either of a document or a document-fragment. Because of this there is no node without a parent. This may causes confusion with "unbound" nodes.

METHODS
=======

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/ ](http://www.w3.org/TR/DOM-Level-3-Core/ )). Please refer to the specification for extensive documentation. 

  * nodeName

        my Str $name = $node.nodeName;

    Returns the node's name. This function is aware of namespaces and returns the full name of the current node (`prefix:localname `). 

    Since 1.62 this function also returns the correct DOM names for node types with constant names, namely: #text, #cdata-section, #comment, #document, #document-fragment. 

  * setNodeName

        $node.setNodeName( $newName );
        $node.nodeName = $newName;

    In very limited situations, it is useful to change a nodes name. In the DOM specification this should throw an error. This Function is aware of namespaces.

  * isSameNode

        my Bool $is-same = $node.isSameNode( $other_node );

    returns True if the given nodes refer to the same node structure, otherwise False is returned.

  * unique-key

        my Str $key = $node.unique-key;

    This function is not specified for any DOM level. It returns a key guaranteed to be unique for this node, and to always be the same value for this node. In other words, two node objects return the same key if and only if isSameNode indicates that they are the same node.

    The returned key value is useful as a key in hashes.

  * nodeValue

        my Str $content = $node.nodeValue;

    If the node has any content (such as stored in a `text node `) it can get requested through this function.

    *NOTE: * Element Nodes have no content per definition. To get the text value of an Element use textContent() instead!

  * textContent

        my Str $content = $node.textContent;

    this function returns the content of all text nodes in the descendants of the given node as specified in DOM.

  * nodeType

        my UInt $type = $node.nodeType;

    Return a numeric value representing the node type of this node. The module LibXML by default exports constants for the node types (see the EXPORT section in the [LibXML ](LibXML ) manual page).

  * unbindNode

        $node.unbindNode();

    Unbinds the Node from its siblings and Parent, but not from the Document it belongs to. If the node is not inserted into the DOM afterwards, it will be lost after the program terminates. From a low level view, the unbound node is stripped from the context it is and inserted into a (hidden) document-fragment.

  * removeChild

        my LibXML::Node $child = $node.removeChild( $node );

    This will unbind the Child Node from its parent `$node `. The function returns the unbound node. If `oldNode ` is not a child of the given Node the function will fail.

  * replaceChild

        $oldnode = $node.replaceChild( $newNode, $oldNode );

    Replaces the `$oldNode ` with the `$newNode `. The `$oldNode ` will be unbound from the Node. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

  * replaceNode

        $node.replaceNode($newNode);

    This function is very similar to replaceChild(), but it replaces the node itself rather than a childnode. This is useful if a node found by any XPath function, should be replaced.

  * appendChild

        $childnode = $node.appendChild( $childnode );

    The function will add the `$childnode ` to the end of `$node `'s children. The function should fail, if the new childnode is already a child of `$node `. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first.

  * addChild

        $childnode = $node.addChild( $childnode );

    This is alias for appendChild (unlike Perl 5 which binds this to xmlAddChild()).

  * addNewChild

        $node = $parent.addNewChild( $nsURI, $name );

    Similar to `addChild() `, this function uses low level libxml2 functionality to provide faster interface for DOM building. *addNewChild() * uses `xmlNewChild() ` to create a new node on a given parent element.

    addNewChild() has two parameters $nsURI and $name, where $nsURI is an (optional) namespace URI. $name is the fully qualified element name; addNewChild() will determine the correct prefix if necessary.

    The function returns the newly created node.

    This function is very useful for DOM building, where a created node can be directly associated with its parent. *NOTE * this function is not part of the DOM specification and its use will limit your code to LibXML.

  * addSibling

        $node.addSibling($newNode);

    addSibling() allows adding an additional node to the end of a nodelist, defined by the given node.

  * cloneNode

        $newnode = $node.cloneNode( $deep );

    *cloneNode * creates a copy of `$node `. When $deep is set to 1 (true) the function will copy all child nodes as well. If $deep is 0 only the current node will be copied. Note that in case of element, attributes are copied even if $deep is 0. 

    Note that the behavior of this function for $deep=0 has changed in 1.62 in order to be consistent with the DOM spec (in older versions attributes and namespace information was not copied for elements).

  * parentNode

        my LibXML::Node $parent = $node.parentNode;

    Returns simply the Parent Node of the current node.

  * nextSibling

        my LibXML::Node $next = $node.nextSibling();

    Returns the next sibling if any .

  * nextNonBlankSibling

        my LibXML::Node $next = $node.nextNonBlankSibling();

    Returns the next non-blank sibling if any (a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * previousSibling

        my LibXML::Node $prev = $node.previousSibling();

    Analogous to *getNextSibling * the function returns the previous sibling if any.

  * previousNonBlankSibling

        my LibXML::Node $prev = $node.previousNonBlankSibling();

    Returns the previous non-blank sibling if any (a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * hasChildNodes

        my Bool $has-kids = $node.hasChildNodes();

    If the current node has child nodes this function returns True, otherwise it returns False.

  * firstChild

        my LibXML::Node $child = $node.firstChild;

    If a node has child nodes this function will return the first node in the child list.

  * lastChild

        my LibXML::Node $child = $node.lastChild;

    If the `$node ` has child nodes this function returns the last child node.

  * ownerDocument

        my LibXML::Document $doc = $node.ownerDocument;

    Through this function it is always possible to access the document the current node is bound to.

  * getOwner

        my LibXML::Node $owner = $node.getOwner;

    This function returns the node the current node is associated with. In most cases this will be a document node or a document fragment node.

  * setOwnerDocument

        $node.setOwnerDocument( $doc );
        $node.ownerDocument = doc;

    This function binds a node to another DOM. This method unbinds the node first, if it is already bound to another document.

    This function is the opposite calling of [LibXML::Document ](LibXML::Document )'s adoptNode() function. Because of this it has the same limitations with Entity References as adoptNode().

  * insertBefore

        $node.insertBefore( $newNode, $refNode );

    The method inserts `$newNode ` before `$refNode `. If `$refNode ` is undefined, the newNode will be set as the new last child of the parent node. This function differs from the DOM L2 specification, in the case, if the new node is not part of the document, the node will be imported first, automatically.

    $refNode has to be passed to the function even if it is undefined:

        $node.insertBefore( $newNode, undef ); # the same as $node.appendChild( $newNode );
         $node.insertBefore( $newNode ); # wrong

    Note, that the reference node has to be a direct child of the node the function is called on. Also, $newChild is not allowed to be an ancestor of the new parent node.

  * insertAfter

        $node.insertAfter( $newNode, $refNode );

    The method inserts `$newNode ` after `$refNode `. If `$refNode ` is undefined, the newNode will be set as the new last child of the parent node.

    Note, that $refNode has to be passed explicitly even if it is undef.

  * findnodes

        my LibXML::Node @nodes = $node.findnodes( $xpath-expression );
        my LibXML::Node::Set $nodes = $node.findnodes( $xpath-expression );

    *findnodes * evaluates the xpath expression (XPath 1.0) on the current node and returns the resulting node set as an array. In scalar context, returns an [LibXML::NodeList ](LibXML::NodeList ) object.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

    *NOTE ON NAMESPACES AND XPATH *:

    A common mistake about XPath is to assume that node tests consisting of an element name with no prefix match elements in the default namespace. This assumption is wrong - by XPath specification, such node tests can only match elements that are in no (i.e. null) namespace. 

    So, for example, one cannot match the root element of an XHTML document with `$node-&gt;find('/html') ` since `'/html' ` would only match if the root element `&lt;html&gt; ` had no namespace, but all XHTML elements belong to the namespace http://www.w3.org/1999/xhtml. (Note that `xmlns="..." ` namespace declarations can also be specified in a DTD, which makes the situation even worse, since the XML document looks as if there was no default namespace). 

    There are several possible ways to deal with namespaces in XPath: 

        * * The recommended way is to use the [LibXML::XPathContext ](LibXML::XPathContext ) module to define an explicit context for XPath evaluation, in which a document independent prefix-to-namespace mapping can be defined. For example: 

        my $xpc = LibXML::XPathContext.new;
        $xpc.registerNs('x', 'http://www.w3.org/1999/xhtml');
        $xpc.find('/x:html', $node);

        * * Another possibility is to use prefixes declared in the queried document (if known). If the document declares a prefix for the namespace in question (and the context node is in the scope of the declaration), `LibXML ` allows you to use the prefix in the XPath expression, e.g.: 

        $node.find('/x:html');

    See also LibXML::XPathContext.findnodes.

  * find

        $result = $node.find( $xpath );

    *find * evaluates the XPath 1.0 expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath "1 * 3 + 52" results in a [LibXML::Number ](LibXML::Number ) object being returned. Other expressions might return an [Bool ](Bool ) object, Numeric, or a [Str ](Str ) object. Each of those objects uses Perl's overload feature to "do the right thing" in different contexts.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

    See also [LibXML::XPathContext ](LibXML::XPathContext ).find.

  * findvalue

        print $node.findvalue( $xpath );

    *findvalue * is exactly equivalent to:

        $node.find( $xpath ).to-literal;

    That is, it returns the literal value of the results. This enables you to ensure that you get a string back from your search, allowing certain shortcuts. This could be used as the equivalent of XSLT's <xsl:value-of select="some_xpath"/>.

    See also [LibXML::XPathContext ](LibXML::XPathContext ).findvalue.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

  * exists

        my Bool $found = $node.exists( $xpath_expression );

    This method behaves like *findnodes *, except that it only returns a boolean value (1 if the expression matches a node, 0 otherwise) and may be faster than *findnodes *, because the XPath evaluation may stop early on the first match (this is true for libxml2 >= 2.6.27). 

    For XPath expressions that do not return node-set, the method returns true if the returned value is a non-zero number or a non-empty string.

  * childNodes

        my LibXML::Node @kids = $node.childNodes();
        my LibXML::Node::List $kids = $node.childNodes();

    *childNodes * implements a more intuitive interface to the childnodes of the current node. It enables you to pass all children directly to a `map ` or `grep `. If this function is called in scalar context, a [LibXML::NodeList ](LibXML::NodeList ) object will be returned.

  * nonBlankChildNodes

        my LibXML::Node @kids = $node.nonBlankChildNodes();
        my LibXML::Node::List $kids = $node.nonBlankChildNodes();

    This is like *childNodes *, but returns only non-blank nodes (where a node is blank if it is a Text or CDATA node consisting of whitespace only). This method is not defined by DOM.

  * Str

        my Str $xml = $node.String(:format);

    This method is similar to the method `Str ` of a [LibXML::Document ](LibXML::Document ) but for a single node. It returns a string consisting of XML serialization of the given node and all its descendants. Unlike `LibXML::Document::Str `.

  * Str: :C14N

        my Str $xml-c14 = $node.Str: :C14N;
        $c14nstring = $node.String, :C14N, :comments, :xpath($xpath-expression);

    The function is similar to Str(). Instead of simply serializing the document tree, it transforms it as it is specified in the XML-C14N Specification (see [http://www.w3.org/TR/xml-c14n ](http://www.w3.org/TR/xml-c14n )). Such transformation is known as canonization.

    If :$comments is False or not specified, the result-document will not contain any comments that exist in the original document. To include comments into the canonized document, :$comments has to be set to True.

    The parameter :$xpath defines the nodeset of nodes that should be visible in the resulting document. This can be used to filter out some nodes. One has to note, that only the nodes that are part of the nodeset, will be included into the result-document. Their child-nodes will not exist in the resulting document, unless they are part of the nodeset defined by the xpath expression. 

    If :$xpath is omitted or empty, Str: :C14N will include all nodes in the given sub-tree, using the following XPath expressions: with comments 

        (. | .//node() | .//@* | .//namespace::*)

    and without comments 

        (. | .//node() | .//@* | .//namespace::*)[not(self::comment())]

    An optional parameter :$selector can be used to pass an [LibXML::XPathContext ](LibXML::XPathContext ) object defining the context for evaluation of $xpath-expression. This is useful for mapping namespace prefixes used in the XPath expression to namespace URIs. Note, however, that $node will be used as the context node for the evaluation, not the context node of :$selector. 

  * Str: :C14N, :v(v1.1)

        $c14nstring = $node.Str: :C14N, :v(v1.1);
        $c14nstring = $node.String: :C14N, :v(v1.1), :comments, :xpath($expression) , :selector($context);

    This function behaves like Str: :C14N except that it uses the "XML_C14N_1_1" constant for canonicalising using the "C14N 1.1 spec". 

  * Str: :C14N, :exclusive

        $ec14nstring = $node.Str: :C14N, :exclusive;
        $ec14nstring = $node.Str: :C14N, :exclusive, :$comments, :xpath($expression), :prefix(@inclusive-list);

    The function is similar to Str: :C14N but follows the XML-EXC-C14N Specification (see [http://www.w3.org/TR/xml-exc-c14n ](http://www.w3.org/TR/xml-exc-c14n )) for exclusive canonization of XML.

    The arguments :comments, :$xpath, :$selector are as in Str: :C14N. :@prefix is a list of namespace prefixes that are to be handled in the manner described by the Canonical XML Recommendation (i.e. preserved in the output even if the namespace is not used). C.f. the spec for details. 

  * serialize

        my Str $xml = $doc.serialize($format);

    An alias for Str. This function was name added to be more consistent with libxml2.

  * serialize-c14n

    An alias for Str: :C14N.

  * serialize-exc-c14n

    An alias for Str: :C14N, :exclusive

  * localname

        my Str $localname = $node.localname;

    Returns the local name of a tag. This is the part behind the colon.

  * prefix

        my Str $prefix = $node.prefix;

    Returns the prefix of a tag. This is the part before the colon.

  * namespaceURI

        my Str $uri = $node.namespaceURI();

    returns the URI of the current namespace.

  * lookupNamespaceURI

        $URI = $node.lookupNamespaceURI( $prefix );

    Find a namespace URI by its prefix starting at the current node.

  * lookupNamespacePrefix

        $prefix = $node.lookupNamespacePrefix( $URI );

    Find a namespace prefix by its URI starting at the current node.

    *NOTE * Only the namespace URIs are meant to be unique. The prefix is only document related. Also the document might have more than a single prefix defined for a namespace.

  * normalize

        $node.normalize;

    This function normalizes adjacent text nodes. This function is not as strict as libxml2's xmlTextMerge() function, since it will not free a node that is still referenced by the perl layer.

  * getNamespaces

        my LibXML::Namespace @ns = $node.getNamespaces;

    If a node has any namespaces defined, this function will return these namespaces. Note, that this will not return all namespaces that are in scope, but only the ones declared explicitly for that node.

    Although getNamespaces is available for all nodes, it only makes sense if used with element nodes.

  * removeChildNodes

        $node.removeChildNodes();

    This function is not specified for any DOM level: It removes all childnodes from a node in a single step. Other than the libxml2 function itself (xmlFreeNodeList), this function will not immediately remove the nodes from the memory. This saves one from getting memory violations, if there are nodes still referred to from the Perl level.

  * baseURI ()

        my Str $URI = $node.baseURI();

    Searches for the base URL of the node. The method should work on both XML and HTML documents even if base mechanisms for these are completely different. It returns the base as defined in RFC 2396 sections "5.1.1. Base URI within Document Content" and "5.1.2. Base URI from the Encapsulating Entity". However it does not return the document base (5.1.3), use method `URI ` of `LibXML::Document ` for this. 

  * setBaseURI ($URI)

        $node.setBaseURI($URI);
        $node.baseURI = $URI;

    This method only does something useful for an element node in an XML document. It sets the xml:base attribute on the node to $strURI, which effectively sets the base URI of the node to the same value. 

    Note: For HTML documents this behaves as if the document was XML which may not be desired, since it does not effectively set the base URI of the node. See RFC 2396 appendix D for an example of how base URI can be specified in HTML. 

  * nodePath

        my Str $path = $node.nodePath();

    This function is not specified for any DOM level: It returns a canonical structure based XPath for a given node.

  * line_number

        my Uint $lineno = $node.line-number();

    This function returns the line number where the tag was found during parsing. If a node is added to the document the line number is 0. Problems may occur, if a node from one document is passed to another one.

    IMPORTANT: Due to limitations in the libxml2 library line numbers greater than 65535 will be returned as 65535. Please see [http://bugzilla.gnome.org/show_bug.cgi?id=325533 ](http://bugzilla.gnome.org/show_bug.cgi?id=325533 ) for more details. 

    Note: linenumber() is special to LibXML and not part of the DOM specification.

    If the line-numbers flag of the parser was not activated before parsing, line-number() will always return 0.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, 

VERSION
=======

2.0200

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

