class LibXML::Element
---------------------

LibXML Class for Element Nodes

Synopsis
--------

```raku
use LibXML::Element;
# Only methods specific to Element nodes are listed here,
# see the LibXML::Node documentation for other methods

my LibXML::Element $elem .= new( $name );

# -- Attribute Methods -- #
$elem.setAttribute( $aname, $avalue );
$elem.setAttributeNS( $nsURI, $aname, $avalue );
my Bool $added = $elem.setAttributeNode($attrnode, :ns);
$elem.removeAttributeNode($attrnode);
$avalue = $elem.getAttribute( $aname );
$avalue = $elem.getAttributeNS( $nsURI, $aname );
$attrnode = $elem.getAttributeNode( $aname );
$attrnode = $elem{'@'~$aname}; # xpath attribute selection
$attrnode = $elem.getAttributeNodeNS( $namespaceURI, $aname );
my Bool $has-atts = $elem.hasAttributes();
my Bool $found = $elem.hasAttribute( $aname );
my Bool $found = $elem.hasAttributeNS( $nsURI, $aname );
my LibXML::Attr::Map $attrs = $elem.attributes();
$attrs = $elem<attributes::>; # xpath
my LibXML::Attr @props = $elem.properties();
my Bool $removed = $elem.removeAttribute( $aname );
$removed = $elem.removeAttributeNS( $nsURI, $aname );

# -- Navigation Methods -- #
my LibXML::Node @nodes = $elem.getChildrenByTagName($tagname);
@nodes = $elem.getChildrenByTagNameNS($nsURI,$tagname);
@nodes = $elem.getChildrenByLocalName($localname);
@nodes = $elem.children; # all child nodes
@nodes = $elem.children(:!blank); # non-blank child nodes
my LibXML::Element @elems = $elem.getElementsByTagName($tagname);
@elems = $elem.getElementsByTagNameNS($nsURI,$localname);
@elems = $elem.getElementsByLocalName($localname);
@elems = $elem.elements; # all child elements

#-- DOM Manipulation Methods -- #
$elem.addNewChild( $nsURI, $name );
$elem.appendWellBalancedChunk( $chunk );
$elem.appendText( $PCDATA );
$elem.appendTextNode( $PCDATA );
$elem.appendTextChild( $childname , $PCDATA );
$elem.setNamespace( $nsURI , $nsPrefix, :$activate );
$elem.setNamespaceDeclURI( $nsPrefix, $newURI );
$elem.setNamespaceDeclPrefix( $oldPrefix, $newPrefix );

# -- Associative interface -- #
@nodes = $elem{$xpath-expression};  # xpath node selection
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
                       'xmlns:mam' => 'urn:mammals', # name-space
                       :foo<bar>,                    # attribute
                       "\n  ",                       # white-space
                       '#comment' => 'demo',         # comment
                       :baz[],                       # sub-element
                       '#cdata' => 'a&b',            # CData section
                       "Some text.",                 # text content
                       "\n"
                   ]
                  );
say $elem;
# <Test xmlns:mam="urn:mammals" foo="bar">
#   <!--demo--><baz/><![CDATA[a&b]]>Some text.
# </Test>
```

The class inherits from [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node). The documentation for Inherited methods is not listed here. 

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/](http://www.w3.org/TR/DOM-Level-3-Core/)). Please refer to the specification for extensive documentation. 

### method new

```raku
# DOMish
multi method new(QName:D $name,LibXML::Namespace :$ns
) returns LibXML::Element
# Rakuish
multi method new(QName:D :$name,LibXML::Namespace :$ns
) returns LibXML::Element
```

Creates a new element node, unbound to any DOM

Attribute Methods
-----------------

### multi method setAttribute

```perl6
multi method setAttribute(
    Str $name where { ... },
    Str:D $value
) returns Bool
```

Sets or replaces the element's $name attribute to $value

### multi method setAttributeNS

```perl6
multi method setAttributeNS(
    Str $uri,
    Str $name where { ... },
    Str $value
) returns LibXML::Attr
```

Namespace-aware version of of setAttribute()

where

  * `$nsURI` is a namespace URI,

  * `$name` is a qualified name, and`

  * `$value` is the value.

The namespace URI may be Str:U (undefined) or blank ('') in order to create an attribute which has no namespace.

The current implementation differs from DOM in the following aspects 

If an attribute with the same local name and namespace URI already exists on the element, but its prefix differs from the prefix of `$aname`, then this function is supposed to change the prefix (regardless of namespace declarations and possible collisions). However, the current implementation does rather the opposite. If a prefix is declared for the namespace URI in the scope of the attribute, then the already declared prefix is used, disregarding the prefix specified in `$aname`. If no prefix is declared for the namespace, the function tries to declare the prefix specified in `$aname` and dies if the prefix is already taken by some other namespace. 

According to DOM Level 2 specification, this method can also be used to create or modify special attributes used for declaring XML namespaces (which belong to the namespace "http://www.w3.org/2000/xmlns/" and have prefix or name "xmlns"). The implementation differs from DOM specification in the following: if a declaration of the same namespace prefix already exists on the element, then changing its value via this method automatically changes the namespace of all elements and attributes in its scope. This is because in libxml2 the namespace URI of an element is not static but is computed from a pointer to a namespace declaration attribute.

### method setAttributeNode

```perl6
method setAttributeNode(
    LibXML::Attr:D $att,
    Bool :$ns
) returns LibXML::Attr
```

Set an attribute node on an element

### method setAttributeNodeNS

```perl6
method setAttributeNodeNS(
    LibXML::Attr:D $att
) returns LibXML::Attr
```

Namespace aware version of setAttributeNode

### method removeAttributeNode

```perl6
method removeAttributeNode(
    LibXML::Attr:D $att
) returns LibXML::Attr
```

Remove an attribute node from an element

### method getAttribute

```raku
method getAttribute(QName $name) returns Str
```

If the object has an attribute with the name `$name`, the value of this attribute will get returned.

### method getAttributeNS

```raku
method getAttributeNS(Str $uri, QName $name) returns Str
```

Retrieves an attribute value by local name and namespace URI.

### method getAttributeNode

```raku
method getAttributeNode(QName $name) returns LibXML::Attr
```

Retrieve an attribute node by name. If no attribute with a given name exists, `LibXML::Attr:U` is returned.

### method getAttributeNodeNS

```raku
method getAttributeNodeNS(Str $uri, QName $name) returns LibXML::Attr
```

Retrieves an attribute node by local name and namespace URI. If no attribute with a given localname and namespace exists, `LibXML::Attr:U` is returned.

### method hasAttribute

```raku
method hasAttribute( QName $name ) returns Bool;
```

This function tests if the named attribute is set for the node. If the attribute is specified, True will be returned, otherwise the return value is False.

### method hasAttributeNS

```raku
method hasAttributeNS(Str $uri, QName $name ) returns Bool;
```

namespace version of `hasAttribute`

### method hasAttributes

```raku
method hasAttributes( ) returns Bool;
```

returns True if the current node has any attributes set, otherwise False is returned.

### method attributes

```raku
method attributes() returns LibXML::Attr::Map
# example:
my LibXML::Attr::Map $atts = $elem.attributes();
for $atts.keys { ... }
$atts<color> = 'red';
$atts<style>:delete;
```

Proves an associative interface to a node's attributes.

Unlike the equivalent Perl 5 method, this method retrieves only [LibXML::Attr](https://libxml-raku.github.io/LibXML-raku/Attr) (not [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace)) nodes.

See also:

  * the `properties` method, which returns a positional [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List) attributes iterator.

  * the `namespaces` method, which returns an [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace) namespaces iterator.

### method properties

```raku
method properties() returns LibXML::Node::List
```

Returns an attribute list for the element node. It can be used to iterate through an elements properties.

Examples:

```raku
my LibXML::Attr @props = $elem.properties;
my LibXML::Node::List $props = $elem.properties;
for $elem.properties -> LibXML::Attr $attr { ... }
```

### method removeAttribute

```raku
method removeAttribute( QName $aname ) returns Bool;
```

This method removes the attribute `$aname` from the node's attribute list, if the attribute can be found.

### method removeAttributeNS

```raku
method removeAttributeNS( $nsURI, $aname ) returns Bool;
```

Namespace version of `removeAttribute`

Navigation Methods
------------------

### method getChildrenByTagName

```raku
method getChildrenByTagName(Str $tagname) returns LibXML::Node::Set;
my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);
```

This method gives direct access to all child elements of the current node with a given tagname, where tagname is a qualified name, that is, in case of namespace usage it may consist of a prefix and local name. This function makes things a lot easier if one needs to handle big data sets. A special tagname '*' can be used to match any name.

### method getChildrenByTagNameNS

```raku
method getChildrenByTagNameNS(Str $nsURI, Str $tagname) returns LibXML::Node::Set;
my LibXML::Element @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
```

Namespace version of `getChildrenByTagName`. A special nsURI '*' matches any namespace URI, in which case the function behaves just like `getChildrenByLocalName`.

### method getChildrenByLocalName

```raku
method getChildrenByLocalName(Str $localname) returns LibXML::Node::Set;
my LibXML::Element @nodes = $node.getChildrenByLocalName($localname);
```

The function gives direct access to all child elements of the current node with a given local name. It makes things a lot easier if one needs to handle big data sets. Note:

  * A special `localname` '*' can be used to match all elements.

  * `@*` can be used to fetch attributes as a node-set

  * `?*` (all), or `?name` can be used to fetch processing instructions

  * The special names `#text`, `#comment` and `#cdata-section` can be used to match Text, Comment or CDATA Section nodes.

### method getElementsByTagName

```raku
method getElementsByTagName(QName $tagname) returns LibXML::Node::Set;
my LibXML::Element @nodes = $node.getElementsByTagName($tagname);
```

This function is part of the spec. It fetches all descendants of a node with a given tagname, where `tagname` is a qualified name, that is, in case of namespace usage it may consist of a prefix and local name. A special `tagname` '*' can be used to match any tag name. 

### method getElementsByTagNameNS

```raku
my LibXML::Element @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
method getElementsByTagNameNS($nsURI, QName $localname) returns LibXML::Node::Set;
```

Namespace version of `getElementsByTagName` as found in the DOM spec. A special `localname` '*' can be used to match any local name and `nsURI` '*' can be used to match any namespace URI.

### method getElementsByLocalName

```raku
my LibXML::Element @nodes = $node.getElementsByLocalName($localname);
my LibXML::Node::Set $nodes = $node.getElementsByLocalName($localname);
```

This function is not found in the DOM specification. It is a mix of getElementsByTagName and getElementsByTagNameNS. It will fetch all tags matching the given local-name. This allows one to select tags with the same local name across namespace borders.

In item context this function returns an [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) object.

### method elements

```raku
method elements() returns LibXML::Node::Set
```

Equivalent to `.getElementsByLocalName('*')`

DOM Manipulation Methods
------------------------

### method namespaces

```raku
method namespaces() returns LibXML::Node::List
my LibXML::Namespace @ns = $node.namespaces;
```

returns a list of Namespace declarations for the node. It can be used to iterate through an element's namespaces:

```raku
for $elem.namespaces -> LibXML::Namespace $ns { ... }
```

### method appendWellBalancedChunk

```raku
method appendWellBalancedChunk( Str $chunk ) returns LibXML::Node
```

Sometimes it is necessary to append a string coded XML Tree to a node. *appendWellBalancedChunk* will do the trick for you. But this is only done if the String is `well-balanced`.

*Note that appendWellBalancedChunk() is only left for compatibility reasons*. Implicitly it uses

```raku
my LibXML::DocumentFragment $fragment = $parser.parse: :balanced, :$chunk;
$node.appendChild( $fragment );
```

This form is more explicit and makes it easier to control the flow of a script.

### method appendText

```raku
method appendText( $PCDATA ) returns LibXML::Text
```

alias for appendTextNode().

### method appendTextNode

```raku
method appendTextNode( $PCDATA ) returns Mu
```

This wrapper function lets you add a string directly to an element node.

### method appendTextChild

```raku
method appendTextChild( QName $childname, $PCDATA ) returns LibXML::Element;
```

Somewhat similar with `appendTextNode`: It lets you set an Element, that contains only a `text node` directly by specifying the name and the text content.

### method setNamespace

```raku
method setNamespace( Str $nsURI, NCName $nsPrefix?, :$activate );
```

setNamespace() allows one to apply a namespace to an element. The function takes a namespace URI, and an optional namespace prefix. If prefix is not given, undefined or empty, this function reuses any existing definition, in the element's scope, or generates a new prefix.

The :activate option is most useful: If this parameter is set to False, a new namespace declaration is simply added to the element while the element's namespace itself is not altered. Nevertheless, activate is set to True on default. In this case the namespace is used as the node's effective namespace. This means the namespace prefix is added to the node name and if there was a namespace already active for the node, it will be replaced (but its declaration is not removed from the document). A new namespace declaration is only created if necessary (that is, if the element is already in the scope of a namespace declaration associating the prefix with the namespace URI, then this declaration is reused). 

The following example may clarify this:

```raku
my $e1 = $doc.createElement("bar");
$e1.setNamespace("http://foobar.org", "foo")
```

results in:

```xml
<foo:bar xmlns:foo="http://foobar.org"/>
```

while:

```raku
my $e2 = $doc.createElement("bar");
$e2.setNamespace("http://foobar.org", "foo", :!activate)
```

results in:

```xml
<bar xmlns:foo="http://foobar.org"/>
```

By using :!activate it is possible to create multiple namespace declarations on a single element.

The function fails if it is required to create a declaration associating the prefix with the namespace URI but the element already carries a declaration with the same prefix but different namespace URI. 

### method requireNamespace

```raku
 use LibXML::Types ::NCName;
 method requireNamespace(Str $uri) returns NCName
```

Return the prefix for any any existing namespace in the node's scope that matches the URL. If not found, a new namespace is created for the URI on the node with an anonymous prefix (_ns0, _ns1, ...).

### method setNamespaceDeclURI

```raku
method setNamespaceDeclURI( NCName $nsPrefix, Str $newURI ) returns Bool
```

This function is NOT part of any DOM API.

This function manipulates directly with an existing namespace declaration on an element. It takes two parameters: the prefix by which it looks up the namespace declaration and a new namespace URI which replaces its previous value.

It returns True if the namespace declaration was found and changed, False otherwise.

All elements and attributes (even those previously unbound from the document) for which the namespace declaration determines their namespace belong to the new namespace after the change. For example:

```raku
my LibXML::Element $elem = .root()
    given LibXML.parse('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>');
$elem.setNamespaceDeclURI( 'xxx', 'http://ns2.com'  );
say $elem.Str; # <Doc xmlns:xxx="http://ns2.com"><xxx:elem/></Doc>
```

If the new URI is undefined or empty, the nodes have no namespace and no prefix after the change. Namespace declarations once nulled in this way do not further appear in the serialized output (but do remain in the document for internal integrity of libxml2 data structures). 

### method setNamespaceDeclPrefix

```raku
method setNamespaceDeclPrefix( NCName $oldPrefix, NCName $newPrefix ) returns Bool
```

This function is NOT part of any DOM API.

This function manipulates directly with an existing namespace declaration on an element. It takes two parameters: the old prefix by which it looks up the namespace declaration and a new prefix which is to replace the old one.

The function dies with an error if the element is in the scope of another declaration whose prefix equals to the new prefix, or if the change should result in a declaration with a non-empty prefix but empty namespace URI. Otherwise, it returns True if the namespace declaration was found and changed, or False if not found.

All elements and attributes (even those previously unbound from the document) for which the namespace declaration determines their namespace change their prefix to the new value. For example:

```raku
my $node = .root()
    given LibXML.parse('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>');
$node.setNamespaceDeclPrefix( 'xxx', 'yyy' );
say $node.Str; # <Doc xmlns:yyy="http://ns.com"><yyy:elem/></Doc>
```

If the new prefix is undefined or empty, the namespace declaration becomes a declaration of a default namespace. The corresponding nodes drop their namespace prefix (but remain in the, now default, namespace). In this case the function fails, if the containing element is in the scope of another default namespace declaration. 

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

