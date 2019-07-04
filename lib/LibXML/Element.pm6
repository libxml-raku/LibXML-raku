use LibXML::Node :iterate-list, :iterate-set, :native-class;
use LibXML::_DOMNode;

unit class LibXML::Element
    is LibXML::Node
    does LibXML::_DOMNode;

use NativeCall;

use LibXML::Attr;
use LibXML::Enums;
use LibXML::Namespace;
use LibXML::Native;
use LibXML::Types :QName, :NCName;
use Method::Also;

my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;

multi submethod TWEAK(xmlNode:D :native($)!) { }
multi submethod TWEAK(:doc($doc-obj), QName :$name!, LibXML::Namespace :ns($ns-obj)) {
    my xmlDoc:D $doc = .native with $doc-obj;
    my xmlNs:D $ns = .native with $ns-obj;
    self.native = xmlNode.new: :$name, :$doc, :$ns;
}

method native is rw handles<
        content
        getAttribute getAttributeNS getNamespaceDeclURI
        hasAttributes hasAttribute hasAttributeNS
        removeAttribute removeAttributeNS
        > { callsame; }

multi method new(QName:D $name, *%o) {
    self.new(:$name, |%o);
}

multi method new(|c) is default { nextsame }

sub iterate-ns(LibXML::Namespace $of, $start, :$doc = $of.doc) {
    # follow a chain of .next links.
    my class NodeList does Iterable does Iterator {
        has $.cur;
        method iterator { self }
        method pull-one {
            my $this = $!cur;
            $_ = .next with $!cur;
            with $this -> $node {
                $of.box: $node, :$doc
            }
            else {
                IterationEnd;
            }
        }
    }.new( :cur($start) );
}

method namespaces {
    iterate-ns(LibXML::Namespace, $.native.nsDef, :$.doc);
}

method !get-attributes {
    require LibXML::Attr::Map;
    LibXML::Attr::Map.new: :node(self);
}

method !set-attributes(%atts) {
    # clear out old attributes
    with $.native.properties -> domNode:D $node is copy {
        while $node.defined {
            my $next = $node.next;
            $node.Release
                if $node.type == XML_ATTRIBUTE_NODE;
            $node = $next;
        }
    }
    # set new attributes
    for %atts.pairs.sort -> $att, {
        if $att.value ~~ NameVal|Hash {
            my $uri = $att.key;
            self.setAttributeNS($uri, $_)
                for $att.value.pairs.sort;
        }
        else {
            self.setAttribute($att.key, $att.value);
        }
    }
}

# hashy attribute containers
method attributes is rw {
    Proxy.new(
        FETCH => sub ($) { self!get-attributes },
        STORE => sub ($, %atts) {
            self!set-attributes(%atts);
        }
    );
}

# attributes as an ordered list
method properties {
    iterate-list(LibXML::Attr, $.native.properties);
}

method appendWellBalancedChunk(Str:D $string) {
    require LibXML::DocumentFragment;
    my $frag = LibXML::DocumentFragment.new;
    $frag.parse: :balanced, :$string;
    self.appendChild( $frag );
}

multi method requireNamespace(Str:D $uri where .so, NCName:D :$prefix! --> NCName) {
    $.lookupNamespacePrefix($uri)
    // ($.setNamespace($uri, $prefix, :!activate) && $prefix)
}

multi method requireNamespace(Str:D $uri where .so --> NCName) {
    $.lookupNamespacePrefix($uri)
    // do {
        my NCName:D $prefix = self.native.genNsPrefix;
        $.setNamespace($uri, $prefix, :!activate)
            && $prefix
    }
}

my subset AttrNode of LibXML::Node where { !.defined || .nodeType == XML_ATTRIBUTE_NODE };
multi method addChild(AttrNode:D $a) { $.setAttributeNode($a) };
multi method addChild(LibXML::Node $c) is default { callsame }
multi method setAttribute(NameVal:D $_) {
    $.native.setAttribute(.key, .value);
}
multi method setAttribute(QName $name, Str:D $value) {
    $.native.setAttribute($name, $value);
}
multi method setAttribute(*%atts) {
    for %atts.pairs.sort -> NameVal $_ {
        $.setAttribute(.key, .value);
    }
}
method setAttributeNode(AttrNode:D $att) {
    $att.keep: $.native.setAttributeNode($att.native);
}
method setAttributeNodeNS(AttrNode:D $att) {
    $att.keep: $.native.setAttributeNodeNS($att.native);
}
multi method setAttributeNS(Str $uri, NameVal:D $_) {
    $.native.setAttributeNS($uri, .key, .value);
}
multi method setAttributeNS(Str $uri, QName $name, Str $value) {
    native-class(XML_ATTRIBUTE_NODE).box: $.native.setAttributeNS($uri, $name, $value);
}
method getAttributeNode(Str $att-name --> LibXML::Node) {
    native-class(XML_ATTRIBUTE_NODE).box: $.native.getAttributeNode($att-name);
}
method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Node) {
    native-class(XML_ATTRIBUTE_NODE).box: $.native.getAttributeNodeNS($uri, $att-name);
}
method removeAttributeNode(AttrNode $att) {
    $att.keep: $.native.removeAttributeNode($att.native), :doc(LibXML::Node);
}

=begin pod
=head1 NAME

LibXML::Element - LibXML Class for Element Nodes

=head1 SYNOPSIS



  use LibXML::Element;
  use LibXML::Attr::Map;
  # Only methods specific to Element nodes are listed here,
  # see the LibXML::Node manpage for other methods

  my LibXML::Element $node .= new( $name );
  $node.setAttribute( $aname, $avalue );
  $node.setAttributeNS( $nsURI, $aname, $avalue );
  $avalue = $node.getAttribute( $aname );
  $avalue = $node.getAttributeNS( $nsURI, $aname );
  $attrnode = $node.getAttributeNode( $aname );
  $attrnode = $node.getAttributeNodeNS( $namespaceURI, $aname );
  my Bool $has-atts = $node.hasAttributes();
  my LibXML::Attr::Map $attrs = $node.attributes();
  my LibXML::Attr @props = $node.properties();
  $node.removeAttribute( $aname );
  $node.removeAttributeNS( $nsURI, $aname );
  $boolean = $node.hasAttribute( $aname );
  $boolean = $node.hasAttributeNS( $nsURI, $aname );
  my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);
  @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
  @nodes = $node.getChildrenByLocalName($localname);
  @nodes = $node.getElementsByTagName($tagname);
  @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
  @nodes = $node.getElementsByLocalName($localname);
  $node.appendWellBalancedChunk( $chunk );
  $node.appendText( $PCDATA );
  $node.appendTextNode( $PCDATA );
  $node.appendTextChild( $childname , $PCDATA );
  $node.setNamespace( $nsURI , $nsPrefix, $activate );
  $node.setNamespaceDeclURI( $nsPrefix, $newURI );
  $node.setNamespaceDeclPrefix( $oldPrefix, $newPrefix );

=head1 METHODS

The class inherits from L<<<<<< LibXML::Node >>>>>>. The documentation for Inherited methods is not listed here. 

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation. 

=begin item1
new

  my LibXML::Element $node .= new( $name );

This function creates a new node unbound to any DOM.

=end item1

=begin item1
setAttribute

  $node.setAttribute( $aname, $avalue );

This method sets or replaces the node's attribute C<<<<<< $aname >>>>>> to the value C<<<<<< $avalue >>>>>>

=end item1

=begin item1
setAttributeNS

  $node.setAttributeNS( $nsURI, $aname, $avalue );

Namespace-aware version of C<<<<<< setAttribute >>>>>>, where C<<<<<< $nsURI >>>>>> is a namespace URI, C<<<<<< $aname >>>>>> is a qualified name, and C<<<<<< $avalue >>>>>> is the value. The namespace URI may be null (empty or undefined) in order to
create an attribute which has no namespace. 

The current implementation differs from DOM in the following aspects 

If an attribute with the same local name and namespace URI already exists on
the element, but its prefix differs from the prefix of C<<<<<< $aname >>>>>>, then this function is supposed to change the prefix (regardless of namespace
declarations and possible collisions). However, the current implementation does
rather the opposite. If a prefix is declared for the namespace URI in the scope
of the attribute, then the already declared prefix is used, disregarding the
prefix specified in C<<<<<< $aname >>>>>>. If no prefix is declared for the namespace, the function tries to declare the
prefix specified in C<<<<<< $aname >>>>>> and dies if the prefix is already taken by some other namespace. 

According to DOM Level 2 specification, this method can also be used to create
or modify special attributes used for declaring XML namespaces (which belong to
the namespace "http://www.w3.org/2000/xmlns/" and have prefix or name "xmlns").
The implementation differs from DOM specification in the following: if a
declaration of the same namespace prefix already exists on the element, then
changing its value via this method automatically changes the namespace of all
elements and attributes in its scope. This is because in libxml2 the namespace
URI of an element is not static but is computed from a pointer to a namespace
declaration attribute.

=end item1

=begin item1
getAttribute

  my Str $avalue = $node.getAttribute( $aname );

If C<<<<<< $node >>>>>> has an attribute with the name C<<<<<< $aname >>>>>>, the value of this attribute will get returned.

=end item1

=begin item1
getAttributeNS

  my Str $avalue = $node.getAttributeNS( $nsURI, $aname );

Retrieves an attribute value by local name and namespace URI.

=end item1

=begin item1
getAttributeNode

  my LibXML::Attr $attrnode = $node.getAttributeNode( $aname );

Retrieve an attribute node by name. If no attribute with a given name exists, C<<<<<< undef >>>>>> is returned.

=end item1

=begin item1
getAttributeNodeNS

  my LibXML::Attr $attrnode = $node.getAttributeNodeNS( $namespaceURI, $aname );

Retrieves an attribute node by local name and namespace URI. If no attribute
with a given localname and namespace exists, C<<<<<< undef >>>>>> is returned.

=end item1

=begin item1
removeAttribute

  my Bool $released = $node.removeAttribute( $aname );

The method removes the attribute C<<<<<< $aname >>>>>> from the node's attribute list, if the attribute can be found.

=end item1

=begin item1
removeAttributeNS

  my Bool $released = $node.removeAttributeNS( $nsURI, $aname );

Namespace version of C<<<<<< removeAttribute >>>>>>

=end item1

=begin item1
hasAttribute

  my Bool $has-this-att = $node.hasAttribute( $aname );

This function tests if the named attribute is set for the node. If the
attribute is specified, True will be returned, otherwise the return value
is False.

=end item1

=begin item1
hasAttributeNS

  my Bool $has-this-att = $node.hasAttributeNS( $nsURI, $aname );

namespace version of C<<<<<< hasAttribute >>>>>>

=end item1

=begin item1
hasAttributes

  my Bool $has-any-atts = $node.hasAttributes();

returns True if the current node has any attributes set, otherwise False is returned.

=end item1

=begin item1
attributes

  use LibXML::Attr::Map;
  my LibXML::Attr::Map $atts = $node.attributes();


This function returns all attributes and namespace declarations assigned to the
given node.

Unlike Perl 5, this method retrieves only LibXML::Attr nodes (not LibXML::Namespace).

 See also:
 =item the C<properties> method, which returns a list of L<LibXML::Attr> attributes.
 =item the C<namespaces> method, which returns a list of L<LibXML::Namespace> namespaces.

=end item1

=begin item
properties

  my LibXML::Attr @props = $node.properties;
  my LibXML::Node::List $props = $node.properties;

returns a list of Attributes for the node.
=end item

=begin item
namespaces

  my LibXML::Namespace @ns = $node.namespaces;
  my LibXML::Node::List $ns = $node.namespaces;

returns a list of Namespace declarations for the node.
=end item

=begin item1
getChildrenByTagName

  my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);
  my LibXML::Node::Set $nodes = $node.getChildrenByTagName($tagname);

The function gives direct access to all child elements of the current node with
a given tagname, where tagname is a qualified name, that is, in case of
namespace usage it may consist of a prefix and local name. This function makes
things a lot easier if one needs to handle big data sets. A special tagname '*'
can be used to match any name.

=end item1

=begin item1
getChildrenByTagNameNS

  my LibXML::Element @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
  my LibXML::Node::Set $nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);

Namespace version of C<<<<<< getChildrenByTagName >>>>>>. A special nsURI '*' matches any namespace URI, in which case the function
behaves just like C<<<<<< getChildrenByLocalName >>>>>>.

=end item1

=begin item1
getChildrenByLocalName

  my LibXML::Element @nodes = $node.getChildrenByLocalName($localname);
  my LibXML::Node::Set $nodes = $node.getChildrenByLocalName($localname);

The function gives direct access to all child elements of the current node with
a given local name. It makes things a lot easier if one needs to handle big
data sets. A special C<<<<<< localname >>>>>> '*' can be used to match any local name.


=end item1

=begin item1
getElementsByTagName

  my LibXML::Element @nodes = $node.getElementsByTagName($tagname);
  my LibXML::Node::Set $nodes = $node.getElementsByTagName($tagname);

This function is part of the spec. It fetches all descendants of a node with a
given tagname, where C<<<<<< tagname >>>>>> is a qualified name, that is, in case of namespace usage it may consist of a
prefix and local name. A special C<<<<<< tagname >>>>>> '*' can be used to match any tag name. 

=end item1

=begin item1
getElementsByTagNameNS

  my LibXML::Element @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
  my LibXML::Node::Set $nodes = $node.getElementsByTagNameNS($nsURI,$localname);

Namespace version of C<<<<<< getElementsByTagName >>>>>> as found in the DOM spec. A special C<<<<<< localname >>>>>> '*' can be used to match any local name and C<<<<<< nsURI >>>>>> '*' can be used to match any namespace URI.


=end item1

=begin item1
getElementsByLocalName

  my LibXML::Element @nodes = $node.getElementsByLocalName($localname);
  my LibXML::Node::Set $nodes = $node.getElementsByLocalName($localname);

This function is not found in the DOM specification. It is a mix of
getElementsByTagName and getElementsByTagNameNS. It will fetch all tags
matching the given local-name. This allows one to select tags with the same
local name across namespace borders.

In SCALAR context this function returns an L<<<<<< LibXML::NodeList >>>>>> object.

=end item1

=begin item1
appendWellBalancedChunk

  $node.appendWellBalancedChunk( $chunk );

Sometimes it is necessary to append a string coded XML Tree to a node. I<<<<<< appendWellBalancedChunk >>>>>> will do the trick for you. But this is only done if the String is C<<<<<< well-balanced >>>>>>.

I<<<<<< Note that appendWellBalancedChunk() is only left for compatibility reasons >>>>>>. Implicitly it uses



  my LibXML::DocumentFragment $fragment = $parser.parse: :balanced, :$chunk;
  $node.appendChild( $fragment );

This form is more explicit and makes it easier to control the flow of a script.

=end item1

=begin item1
appendText

  $node.appendText( $PCDATA );

alias for appendTextNode().

=end item1

=begin item1
appendTextNode

  $node.appendTextNode( $PCDATA );

This wrapper function lets you add a string directly to an element node.

=end item1

=begin item1
appendTextChild

  $node.appendTextChild( $childname , $PCDATA );

Somewhat similar with C<<<<<< appendTextNode >>>>>>: It lets you set an Element, that contains only a C<<<<<< text node >>>>>> directly by specifying the name and the text content.

=end item1

=begin item1
setNamespace

  $node.setNamespace( $nsURI , $nsPrefix, :$activate );

setNamespace() allows one to apply a namespace to an element. The function
takes three parameters: 1. the namespace URI, which is required and the two
optional values prefix, which is the namespace prefix, as it should be used in
child elements or attributes as well as the additional activate parameter. If
prefix is not given, undefined or empty, this function tries to create a
declaration of the default namespace. 

The activate parameter is most useful: If this parameter is set to False, a
new namespace declaration is simply added to the element while the element's
namespace itself is not altered. Nevertheless, activate is set to True on
default. In this case the namespace is used as the node's effective namespace.
This means the namespace prefix is added to the node name and if there was a
namespace already active for the node, it will be replaced (but its declaration
is not removed from the document). A new namespace declaration is only created
if necessary (that is, if the element is already in the scope of a namespace
declaration associating the prefix with the namespace URI, then this
declaration is reused). 

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

By using :!activate it is possible to create multiple namespace
declarations on a single element.

The function fails if it is required to create a declaration associating the
prefix with the namespace URI but the element already carries a declaration
with the same prefix but different namespace URI. 

=end item1

=begin item1
requireNamespace

   my $prefix = $node.requireNamespace(<http://myns.org>, :prefix<xx>)
     || $node.requireNamespace(<http://myns.org>)
  
Creates a namespace definition for the URI, if and only if there is not
already a namespace in the node's scope for the URI. If a prefix is given
the namespace must also have the given prefix.

If no prefix is given, a prefix is returned for any existing namespace
matching the URL. If not found, a new namespace is created for the URI
with an anonimised prefix (_ns0, _ns1, ...).

=end item1

=begin item1
setNamespaceDeclURI

  $node.setNamespaceDeclURI( $nsPrefix, $newURI );

This function is NOT part of any DOM API.

This function manipulates directly with an existing namespace declaration on an
element. It takes two parameters: the prefix by which it looks up the namespace
declaration and a new namespace URI which replaces its previous value.

It returns 1 if the namespace declaration was found and changed, 0 otherwise.

All elements and attributes (even those previously unbound from the document)
for which the namespace declaration determines their namespace belong to the
new namespace after the change. 

If the new URI is undef or empty, the nodes have no namespace and no prefix
after the change. Namespace declarations once nulled in this way do not further
appear in the serialized output (but do remain in the document for internal
integrity of libxml2 data structures). 

=end item1

=begin item1
setNamespaceDeclPrefix

  $node.setNamespaceDeclPrefix( $oldPrefix, $newPrefix );

This function is NOT part of any DOM API.

This function manipulates directly with an existing namespace declaration on an
element. It takes two parameters: the old prefix by which it looks up the
namespace declaration and a new prefix which is to replace the old one.

The function dies with an error if the element is in the scope of another
declaration whose prefix equals to the new prefix, or if the change should
result in a declaration with a non-empty prefix but empty namespace URI.
Otherwise, it returns True if the namespace declaration was found and changed,
or False if not found.

All elements and attributes (even those previously unbound from the document)
for which the namespace declaration determines their namespace change their
prefix to the new value. 

If the new prefix is undef or empty, the namespace declaration becomes a
declaration of a default namespace. The corresponding nodes drop their
namespace prefix (but remain in the, now default, namespace). In this case the
function fails, if the containing element is in the scope of another default
namespace declaration. 

=end item1


=head1 AUTHORS

Matt Sergeant, 
Christian Glahn, 
Petr Pajas, 

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
