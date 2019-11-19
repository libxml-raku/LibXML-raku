NAME
====

LibXML::Element - LibXML Class for Element Nodes

SYNOPSIS
========

    use LibXML::Element;
    # Only methods specific to Element nodes are listed here,
    # see the LibXML::Node documentation for other methods

    my LibXML::Element $node .= new( $name );

    # -- Attributes -- #
    $node.setAttribute( $aname, $avalue );
    $node.setAttributeNS( $nsURI, $aname, $avalue );
    $avalue = $node.getAttribute( $aname );
    $avalue = $node.getAttributeNS( $nsURI, $aname );
    $attrnode = $node.getAttributeNode( $aname );
    $attrnode = $node{'@'~$aname}; # xpath attribute selection
    $attrnode = $node.getAttributeNodeNS( $namespaceURI, $aname );
    my Bool $has-atts = $node.hasAttributes();
    my LibXML::Attr::Map $attrs = $node.attributes();
    $attrs = $node<attributes::>; # xpath
    my LibXML::Attr @props = $node.properties();
    $node.removeAttribute( $aname );
    $node.removeAttributeNS( $nsURI, $aname );
    $boolean = $node.hasAttribute( $aname );
    $boolean = $node.hasAttributeNS( $nsURI, $aname );

    # -- Navigation -- #
    my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);
    @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
    @nodes = $node.getChildrenByLocalName($localname);
    @nodes = $node.children; # all child nodes
    @nodes = $node.children(:!blank); # non-blank child nodes
    my LibXML::Element @elems = $node.getElementsByTagName($tagname);
    @elems = $node.getElementsByTagNameNS($nsURI,$localname);
    @elems = $node.getElementsByLocalName($localname);
    @elems = $node.elements; # all child elements

    #-- DOM Manipulation -- #
    $node.appendWellBalancedChunk( $chunk );
    $node.appendText( $PCDATA );
    $node.appendTextNode( $PCDATA );
    $node.appendTextChild( $childname , $PCDATA );
    $node.setNamespace( $nsURI , $nsPrefix, :$activate );
    $node.setNamespaceDeclURI( $nsPrefix, $newURI );
    $node.setNamespaceDeclPrefix( $oldPrefix, $newPrefix );

    # -- Associative/XPath interface -- #
    @nodes = $node{$xpath-expression};  # xpath node selection
    my LibXML::Element @as = $elem<a>;  # equiv: $elem.getChildrenByLocalName('a');
    my $b-value  = $elem<@b>.Str;       # value of 'b' attribute
    my LibXML::Element @z-grand-kids = $elem<*/z>;   # equiv: $elem.findnodes('*/z', :deref);
    my $text-content = $elem<text()>;
    say $_ for $elem.keys;   # @att-1 .. @att-n .. tag-1 .. tag-n
    say $_ for $elem.attributes.keys;   # att-1 .. att-n
    say $_ for $elem.childNodes.keys;   # 0, 1, ...

    # -- Construction -- #
    use LibXML::Item :&ast-to-xml;
    $elem = ast-to-xml('Test' => [
                           'xmlns:mam' => 'urn:mammals', # namespace
                           :foo<bar>,                    # attribute
                           "\n  ",                       # whitespace
                           '#comment' => 'demo',         # comment
                           :baz[],                       # sub-element
                           '#cdata' => 'a&b',            # CData section
                           "Some text.\n",               # text content
                       ]
                      );
    say $elem;
    # <Test xmlns:mam="urn:mammals" foo="bar">
    #   <!--demo--><baz/><![CDATA[a&b]]>Some text.
    # </Test>

METHODS
=======

The class inherits from [LibXML::Node ](LibXML::Node ). The documentation for Inherited methods is not listed here. 

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/ ](http://www.w3.org/TR/DOM-Level-3-Core/ )). Please refer to the specification for extensive documentation. 

  * new

        my LibXML::Element $node .= new( $name );

    This function creates a new node unbound to any DOM.

  * setAttribute

        $node.setAttribute( $aname, $avalue );

    This method sets or replaces the node's attribute `$aname ` to the value `$avalue `

  * setAttributeNS

        $node.setAttributeNS( $nsURI, $aname, $avalue );

    Namespace-aware version of `setAttribute `, where `$nsURI ` is a namespace URI, `$aname ` is a qualified name, and `$avalue ` is the value. The namespace URI may be null (empty or undefined) in order to create an attribute which has no namespace. 

    The current implementation differs from DOM in the following aspects 

    If an attribute with the same local name and namespace URI already exists on the element, but its prefix differs from the prefix of `$aname `, then this function is supposed to change the prefix (regardless of namespace declarations and possible collisions). However, the current implementation does rather the opposite. If a prefix is declared for the namespace URI in the scope of the attribute, then the already declared prefix is used, disregarding the prefix specified in `$aname `. If no prefix is declared for the namespace, the function tries to declare the prefix specified in `$aname ` and dies if the prefix is already taken by some other namespace. 

    According to DOM Level 2 specification, this method can also be used to create or modify special attributes used for declaring XML namespaces (which belong to the namespace "http://www.w3.org/2000/xmlns/" and have prefix or name "xmlns"). The implementation differs from DOM specification in the following: if a declaration of the same namespace prefix already exists on the element, then changing its value via this method automatically changes the namespace of all elements and attributes in its scope. This is because in libxml2 the namespace URI of an element is not static but is computed from a pointer to a namespace declaration attribute.

  * getAttribute

        my Str $avalue = $node.getAttribute( $aname );

    If `$node ` has an attribute with the name `$aname `, the value of this attribute will get returned.

  * getAttributeNS

        my Str $avalue = $node.getAttributeNS( $nsURI, $aname );

    Retrieves an attribute value by local name and namespace URI.

  * getAttributeNode

        my LibXML::Attr $attrnode = $node.getAttributeNode( $aname );

    Retrieve an attribute node by name. If no attribute with a given name exists, `LibXML::Attr:U ` is returned.

  * getAttributeNodeNS

        my LibXML::Attr $attrnode = $node.getAttributeNodeNS( $namespaceURI, $aname );

    Retrieves an attribute node by local name and namespace URI. If no attribute with a given localname and namespace exists, `LibXML::Attr:U ` is returned.

  * removeAttribute

        my Bool $released = $node.removeAttribute( $aname );

    The method removes the attribute `$aname ` from the node's attribute list, if the attribute can be found.

  * removeAttributeNS

        my Bool $released = $node.removeAttributeNS( $nsURI, $aname );

    Namespace version of `removeAttribute `

  * hasAttribute

        my Bool $has-this-att = $node.hasAttribute( $aname );

    This function tests if the named attribute is set for the node. If the attribute is specified, True will be returned, otherwise the return value is False.

  * hasAttributeNS

        my Bool $has-this-att = $node.hasAttributeNS( $nsURI, $aname );

    namespace version of `hasAttribute `

  * hasAttributes

        my Bool $has-any-atts = $node.hasAttributes();

    returns True if the current node has any attributes set, otherwise False is returned.

  * attributes

        use LibXML::Attr::Map;
        my LibXML::Attr::Map $atts = $elem.attributes();

        for $atts.keys { ... }
        $atts<color> = 'red';
        $atts<style>:delete;

    Proves an associative interface to a node's attributes.

    Unlike the equivalent Perl 5 method, this method retrieves only LibXML::Attr nodes (not LibXML::Namespace).

    See also:

      * the `properties` method, which returns an [LibXML::Attr](LibXML::Attr) attributes iterator.

      * the `namespaces` method, which returns an [LibXML::Namespace](LibXML::Namespace) namespaces iterator.

  * properties

        my LibXML::Attr @props = $elem.properties;
        my LibXML::Node::List $props = $elem.properties;

    returns attributes for the node. It can be used to iterate through an elements properties:

        for $elem.properties -> LibXML::Attr $attr { ... }

  * namespaces

        my LibXML::Namespace @ns = $node.namespaces;
        my LibXML::Node::List $ns = $node.namespaces;

    returns a list of Namespace declarations for the node. It can be used to iterate through an element's namespaces:

        for $elem.namespaces -> LibXML::Namespace $ns { ... }

  * getChildrenByTagName

        my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);
        my LibXML::Node::Set $nodes = $node.getChildrenByTagName($tagname);

    The function gives direct access to all child elements of the current node with a given tagname, where tagname is a qualified name, that is, in case of namespace usage it may consist of a prefix and local name. This function makes things a lot easier if one needs to handle big data sets. A special tagname '*' can be used to match any name.

  * getChildrenByTagNameNS

        my LibXML::Element @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
        my LibXML::Node::Set $nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);

    Namespace version of `getChildrenByTagName `. A special nsURI '*' matches any namespace URI, in which case the function behaves just like `getChildrenByLocalName `.

  * getChildrenByLocalName

        my LibXML::Element @nodes = $node.getChildrenByLocalName($localname);
        my LibXML::Node::Set $nodes = $node.getChildrenByLocalName($localname);

    The function gives direct access to all child elements of the current node with a given local name. It makes things a lot easier if one needs to handle big data sets. Note:

      * A special `localname ` '*' can be used to match all ements.

      * `@*` can be used to fetch attributes as a node-set

      * `?*` (all), or `?name` can be used to fetch processing instructions

      * The special names `#text`, `#comment` and `#cdata` can be used to match Text, Comment or CDATA nodes.

  * getElementsByTagName

        my LibXML::Element @nodes = $node.getElementsByTagName($tagname);
        my LibXML::Node::Set $nodes = $node.getElementsByTagName($tagname);

    This function is part of the spec. It fetches all descendants of a node with a given tagname, where `tagname ` is a qualified name, that is, in case of namespace usage it may consist of a prefix and local name. A special `tagname ` '*' can be used to match any tag name. 

  * getElementsByTagNameNS

        my LibXML::Element @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
        my LibXML::Node::Set $nodes = $node.getElementsByTagNameNS($nsURI,$localname);

    Namespace version of `getElementsByTagName ` as found in the DOM spec. A special `localname ` '*' can be used to match any local name and `nsURI ` '*' can be used to match any namespace URI.

  * getElementsByLocalName

        my LibXML::Element @nodes = $node.getElementsByLocalName($localname);
        my LibXML::Node::Set $nodes = $node.getElementsByLocalName($localname);

    This function is not found in the DOM specification. It is a mix of getElementsByTagName and getElementsByTagNameNS. It will fetch all tags matching the given local-name. This allows one to select tags with the same local name across namespace borders.

    In item context this function returns an [LibXML::Node::Set ](LibXML::Node::Set ) object.

  * elements

    Equivalent to `.getElementsByLocalName('*')`

  * appendWellBalancedChunk

        $node.appendWellBalancedChunk( $chunk );

    Sometimes it is necessary to append a string coded XML Tree to a node. *appendWellBalancedChunk * will do the trick for you. But this is only done if the String is `well-balanced `.

    *Note that appendWellBalancedChunk() is only left for compatibility reasons *. Implicitly it uses

        my LibXML::DocumentFragment $fragment = $parser.parse: :balanced, :$chunk;
        $node.appendChild( $fragment );

    This form is more explicit and makes it easier to control the flow of a script.

  * appendText

        $node.appendText( $PCDATA );

    alias for appendTextNode().

  * appendTextNode

        $node.appendTextNode( $PCDATA );

    This wrapper function lets you add a string directly to an element node.

  * appendTextChild

        $node.appendTextChild( $childname , $PCDATA );

    Somewhat similar with `appendTextNode `: It lets you set an Element, that contains only a `text node ` directly by specifying the name and the text content.

  * setNamespace

        $node.setNamespace( $nsURI , $nsPrefix, :$activate );

    setNamespace() allows one to apply a namespace to an element. The function takes three parameters: 1. the namespace URI, which is required and the two optional values prefix, which is the namespace prefix, as it should be used in child elements or attributes as well as the additional activate parameter. If prefix is not given, undefined or empty, this function tries to create a declaration of the default namespace. 

    The activate parameter is most useful: If this parameter is set to False, a new namespace declaration is simply added to the element while the element's namespace itself is not altered. Nevertheless, activate is set to True on default. In this case the namespace is used as the node's effective namespace. This means the namespace prefix is added to the node name and if there was a namespace already active for the node, it will be replaced (but its declaration is not removed from the document). A new namespace declaration is only created if necessary (that is, if the element is already in the scope of a namespace declaration associating the prefix with the namespace URI, then this declaration is reused). 

    The following example may clarify this:

        my $e1 = $doc.createElement("bar");
        $e1.setNamespace("http://foobar.org", "foo")

    results

        <foo:bar xmlns:foo="http://foobar.org"/>

    while

        my $e2 = $doc.createElement("bar");
        $e2.setNamespace("http://foobar.org", "foo", :!activate)

    results only

        <bar xmlns:foo="http://foobar.org"/>

    By using :!activate it is possible to create multiple namespace declarations on a single element.

    The function fails if it is required to create a declaration associating the prefix with the namespace URI but the element already carries a declaration with the same prefix but different namespace URI. 

  * requireNamespace

        use LibXML::Types ::NCName;
        my NCName:D $prefix = $node.requireNamespace(<http://myns.org>)

    Return the prefix for any any existing namespace in the node's scope that matches the URL. If not found, a new namespace is created for the URI on the node with an anonimised prefix (_ns0, _ns1, ...).

  * setNamespaceDeclURI

        $node.setNamespaceDeclURI( $nsPrefix, $newURI );

    This function is NOT part of any DOM API.

    This function manipulates directly with an existing namespace declaration on an element. It takes two parameters: the prefix by which it looks up the namespace declaration and a new namespace URI which replaces its previous value.

    It returns True if the namespace declaration was found and changed, False otherwise.

    All elements and attributes (even those previously unbound from the document) for which the namespace declaration determines their namespace belong to the new namespace after the change. For example:

        my $node = LibXML.load('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>').root;
        $node.setNamespaceDeclURI( 'xxx', 'http://ns2.com'  );
        say $node.Str; # <Doc xmlns:xxx="http://ns2.com"><xxx:elem/></Doc>

    If the new URI is undefined or empty, the nodes have no namespace and no prefix after the change. Namespace declarations once nulled in this way do not further appear in the serialized output (but do remain in the document for internal integrity of libxml2 data structures). 

  * setNamespaceDeclPrefix

        $node.setNamespaceDeclPrefix( $oldPrefix, $newPrefix );

    This function is NOT part of any DOM API.

    This function manipulates directly with an existing namespace declaration on an element. It takes two parameters: the old prefix by which it looks up the namespace declaration and a new prefix which is to replace the old one.

    The function dies with an error if the element is in the scope of another declaration whose prefix equals to the new prefix, or if the change should result in a declaration with a non-empty prefix but empty namespace URI. Otherwise, it returns True if the namespace declaration was found and changed, or False if not found.

    All elements and attributes (even those previously unbound from the document) for which the namespace declaration determines their namespace change their prefix to the new value. For example:

        my $node = LibXML.load('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>').root;
        $node.setNamespaceDeclPrefix( 'xxx', 'yyy' );
        say $node.Str; # <Doc xmlns:yyy="http://ns.com"><yyy:elem/></Doc>

    If the new prefix is undefined or empty, the namespace declaration becomes a declaration of a default namespace. The corresponding nodes drop their namespace prefix (but remain in the, now default, namespace). In this case the function fails, if the containing element is in the scope of another default namespace declaration. 

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

