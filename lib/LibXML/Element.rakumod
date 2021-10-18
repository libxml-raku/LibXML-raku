use LibXML::Node :&iterate-list;
use LibXML::_ParentNode;
use W3C::DOM;

#| LibXML Class for Element Nodes
unit class LibXML::Element
    is repr('CPointer')
    is LibXML::Node
    does LibXML::_ParentNode
    does W3C::DOM::Element;

=begin pod
    =head2 Synopsis

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
        @elems = $elem.elements; # immediate child elements

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
        $elem = ast-to-xml(
            'Test' => [
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

    The class inherits from L<LibXML::Node>. The documentation for Inherited methods is not listed here. 

    Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation. 

=end pod

use NativeCall;

use LibXML::Attr;
use LibXML::Attr::Map;
use LibXML::Config;
use LibXML::Dtd::ElementDecl;
use LibXML::Enums;
use LibXML::Item :box-class, :dom-boxed;
use LibXML::Namespace;
use LibXML::Raw;
use LibXML::Types :QName, :NCName, :NameVal;
use XML::Grammar;
use Method::Also;

# Perl compat
multi method new(QName:D $name, LibXML::Namespace $ns?) {
    self.new(:$name, :$ns);
}
multi method new(LibXML::Node :doc($owner), QName :$name!, LibXML::Namespace :ns($ns-obj)) {
    my xmlDoc:D $doc = .raw with $owner;
    my xmlNs:D $ns = .raw with $ns-obj;
    my $raw := xmlElem.new( :$name, :$doc, :$ns );
    self.box: $raw;
}

method raw handles<
        content
        getAttribute getAttributeNS getNamespaceDeclURI
        hasAttribute hasAttributeNS
        removeAttribute removeAttributeNS> {
    nativecast(xmlElem, self);
}

=begin pod
    =head3 method new

        # DOMish
        multi method new(QName:D $name, LibXML::Namespace :$ns
        ) returns LibXML::Element
        # Rakuish
        multi method new(QName:D :$name, LibXML::Namespace :$ns
        ) returns LibXML::Element

    Creates a new element node, unbound to any DOM
=end pod


########################################################################
=head2 Attribute Methods

method !set-attr(QName $name, Str:D $value) {
    ? $.raw.setAttribute($name, $value);
}
multi method setAttribute(NameVal:D $_ --> Bool) {
    self!set-attr(.key, .value);
}
#| Sets or replaces the element's $name attribute to  $value
multi method setAttribute(QName $name, Str:D $value --> Bool) {
    self!set-attr($name, $value);
}
multi method setAttribute(*%atts) {
    self!set-attr(.key, .value)
        for %atts.pairs.sort;
}
multi method setAttributeNS(Str $uri, NameVal:D $_ --> LibXML::Attr) {
    $.setAttributeNS($uri, .key, .value);
}
#| Namespace-aware version of of setAttribute()
multi method setAttributeNS(Str $uri, QName $name, Str $value --> LibXML::Attr) {
    &?ROUTINE.returns.box: $.raw.setAttributeNS($uri, $name, $value);
}
=begin pod
    =para  where
        =item `$nsURI` is a namespace URI,
        =item `$name` is a qualified name, and`
        =item `$value` is the value.

    The namespace URI may be Str:U (undefined) or blank ('') in order to
    create an attribute which has no namespace.

    The current implementation differs from DOM in the following aspects 

    If an attribute with the same local name and namespace URI already exists on
    the element, but its prefix differs from the prefix of C<$aname>, then this
    function is supposed to change the prefix (regardless of namespace declarations
    and possible collisions). However, the current implementation does rather the
    opposite. If a prefix is declared for the namespace URI in the scope of the
    attribute, then the already declared prefix is used, disregarding the prefix
    specified in C<$aname>. If no prefix is declared for the namespace, the function
    tries to declare the prefix specified in C<$aname> and dies if the prefix is
    already taken by some other namespace.

    According to DOM Level 2 specification, this method can also be used to create
    or modify special attributes used for declaring XML namespaces (which belong to
    the namespace "http://www.w3.org/2000/xmlns/" and have prefix or name "xmlns").
    The implementation differs from DOM specification in the following: if a
    declaration of the same namespace prefix already exists on the element, then
    changing its value via this method automatically changes the namespace of all
    elements and attributes in its scope. This is because in libxml2 the namespace
    URI of an element is not static but is computed from a pointer to a namespace
    declaration attribute.
=end pod

#| Set an attribute node on an element
method setAttributeNode(LibXML::Attr:D $att, Bool :$ns --> LibXML::Attr) {
    $ns
        ?? self.setAttributeNodeNS($att)
        !! $att.keep: $.raw.setAttributeNode($att.raw);
}
#| Namespace aware version of setAttributeNode
method setAttributeNodeNS(LibXML::Attr:D $att --> LibXML::Attr) {
    $att.keep: $.raw.setAttributeNodeNS($att.raw);
}

#| Remove an attribute node from an element
method removeAttributeNode(LibXML::Attr:D $att --> LibXML::Attr) {
    $att.keep: $.raw.removeAttributeNode($att.raw), :doc(LibXML::Node);
}

method getAttributeNode(Str:D $att-name --> LibXML::Attr) is also<attribute> {
    LibXML::Attr.box: $.raw.getAttributeNode($att-name);
}
method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Attr) {
    LibXML::Attr.box: $.raw.getAttributeNodeNS($uri, $att-name);
}

# handled by the `raw` method
=begin pod
    =head3 method getAttribute

        method getAttribute(QName $name) returns Str

    If the object has an attribute with the name C<$name>, the value of this attribute will get returned.

    =head3 method getAttributeNS

        method getAttributeNS(Str $uri, QName $name) returns Str

    Retrieves an attribute value by local name and namespace URI.

    =head3 method getAttributeNode

        method getAttributeNode(QName $name) returns LibXML::Attr

    Retrieve an attribute node by name. If no attribute with a given name exists, C<LibXML::Attr:U> is returned.

    =head3 method getAttributeNodeNS

        method getAttributeNodeNS(Str $uri, QName $name) returns LibXML::Attr

    Retrieves an attribute node by local name and namespace URI. If no attribute
    with a given localname and namespace exists, C<LibXML::Attr:U> is returned.

    =head3 method hasAttribute

        method hasAttribute( QName $name ) returns Bool;

    This function tests if the named attribute is set for the node. If the
    attribute is specified, True will be returned, otherwise the return value
    is False.

    =head3 method hasAttributeNS

        method hasAttributeNS(Str $uri, QName $name ) returns Bool;

    namespace version of C<hasAttribute>

    =head3 method hasAttributes

        method hasAttributes( ) returns Bool;

    Returns True if the current node has any attributes set, otherwise False is returned.

=end pod

method attributes(LibXML::Element:D $node:) is rw is also<attribs attr> {
    Proxy.new(
        FETCH => {
            LibXML::Attr::Map.new: :$node
        },
        STORE => sub ($, %atts) {
            self!set-attributes: %atts.pairs.sort;
        }
    );
}
=begin pod
    =head3 method attributes

      method attributes() returns LibXML::Attr::Map
      # example:
      my LibXML::Attr::Map $atts = $elem.attributes();
      for $atts.keys { ... }
      $atts<color> = 'red';
      $atts<style>:delete;

    Proves an associative interface to a node's attributes.

    Unlike the equivalent Perl method, this method retrieves only L<LibXML::Attr> (not L<LibXML::Namespace>) nodes.

    See also:

      =item the C<properties> method, which returns a positional L<LibXML::Node::List> attributes iterator.

      =item the C<namespaces> method, which returns an L<LibXML::Namespace> namespaces iterator.

=end pod

method properties {
    iterate-list(self, LibXML::Attr);
}
=begin pod

    =head3 method properties

        method properties() returns LibXML::Node::List

    Returns an attribute list for the element node. It can be used to iterate through an elements properties.

    Examples:

        my LibXML::Attr @props = $elem.properties;
        my LibXML::Node::List $props = $elem.properties;
        for $elem.properties -> LibXML::Attr $attr { ... }

    =head3 method removeAttribute

        method removeAttribute( QName $aname ) returns Bool;

    This method removes the attribute C<$aname> from the node's attribute list, if the attribute can be found.

    =head3 method removeAttributeNS

        method removeAttributeNS( $nsURI, $aname ) returns Bool;

    Namespace version of C<removeAttribute>

=end pod

method !set-attributes(@atts) {
    # clear out old attributes
    with $.raw.properties -> anyNode:D $node is copy {
        while $node.defined {
            my $next = $node.next;
            $node.Release
                if $node.type == XML_ATTRIBUTE_NODE;
            $node = $next;
        }
    }
    # set new attributes
    for @atts -> $att, {
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

########################################################################
=head2 Navigation Methods

# From role LibXML::_ParentNode (also applicable to document fragments
# and documents    
=begin pod

    =head3 method getChildrenByTagName

      method getChildrenByTagName(Str $tagname) returns LibXML::Node::Set;
      my LibXML::Node @nodes = $node.getChildrenByTagName($tagname);

    This method gives direct access to all child elements of the current node with
    a given tagname, where tagname is a qualified name, that is, in case of
    namespace usage it may consist of a prefix and local name. This function makes
    things a lot easier if one needs to handle big data sets. A special tagname '*'
    can be used to match any name.

    =head3 method getChildrenByTagNameNS

      method getChildrenByTagNameNS(Str $nsURI, Str $tagname) returns LibXML::Node::Set;
      my LibXML::Element @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);

    Namespace version of C<getChildrenByTagName>. A special nsURI '*' matches any namespace URI, in which case the function
    behaves just like C<getChildrenByLocalName>.


    =head3 method getChildrenByLocalName

      method getChildrenByLocalName(Str $localname) returns LibXML::Node::Set;
      my LibXML::Element @nodes = $node.getChildrenByLocalName($localname);

    =para
    The function gives direct access to all child elements of the current node with
    a given local name. It makes things a lot easier if one needs to handle big
    data sets. Note:

      =item A special C<localname> '*' can be used to match all elements.
      =item C<@*> can be used to fetch attributes as a node-set
      =item C<?*> (all), or C<?name> can be used to fetch processing instructions
      =item The special names C<#text>, C<#comment> and C<#cdata-section> can be used to match Text, Comment or CDATA Section nodes.


    =head3 method getElementsByTagName

      method getElementsByTagName(QName $tagname) returns LibXML::Node::Set;
      my LibXML::Element @nodes = $node.getElementsByTagName($tagname);

    =para
    This function is part of the spec. It fetches all descendants of a node with a
    given tagname, where C<tagname> is a qualified name, that is, in case of namespace usage it may consist of a
    prefix and local name. A special C<tagname> '*' can be used to match any tag name. 


    =head3 method getElementsByTagNameNS

      my LibXML::Element @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
      method getElementsByTagNameNS($nsURI, QName $localname) returns LibXML::Node::Set;

    =para
    Namespace version of C<getElementsByTagName> as found in the DOM spec. A special C<localname> '*' can be used to match any local name and C<nsURI> '*' can be used to match any namespace URI.


    =head3 method getElementsByLocalName

      my LibXML::Element @nodes = $node.getElementsByLocalName($localname);
      my LibXML::Node::Set $nodes = $node.getElementsByLocalName($localname);

    This function is not found in the DOM specification. It is a mix of
    getElementsByTagName and getElementsByTagNameNS. It will fetch all tags
    matching the given local-name. This allows one to select tags with the same
    local name across namespace borders.

    In item context this function returns an L<LibXML::Node::Set> object.

    =head3 method elements

        method elements() returns LibXML::Node::Set

    Returns all immediate child elements.
        
    Equivalent to `.getElementsByLocalName('*')`

=end pod

########################################################################
=head2 DOM Manipulation Methods

method ast(Bool :$blank = LibXML::Config.keep-blanks) {
    self.tag => [
        slip(self.namespaces>>.ast),
        slip(self.properties>>.ast),
        slip(self.children(:$blank)>>.ast(:$blank)),
    ]
}

multi method AT-KEY('@*') is rw { self.attributes }
multi method AT-KEY('attributes::') is rw { self.attributes }
multi method AT-KEY(Str:D $ where /^['@'|'attribute::']<name=.XML::Grammar::name>$/) is rw {
    my Str:D $name = $<name>.Str;
    my Str $href;

    if $name.contains(':') {
        # Dissect namespace
        my ($pfx, $local-name) = $name.split(':', 2);
        given $pfx {
            when 'xml'|'' { } # do nothing
            when 'xmlns' {
                fail "'xmlns' prefix is reserved"
            }
            default {
                $href = self.xpath-context.lookupNs(.Str)
                    // fail "unknown namespace prefix $_";
                $name = $local-name;
            }
        }
    }

    Proxy.new(
        FETCH => { $.getAttributeNodeNS($href, $name) },
        STORE => sub ($, Str() $val) {
            $.setAttributeNS($href, $name, $val);
        }
    );
}

method appendWellBalancedChunk(Str:D $string --> LibXML::Node) {
    my $frag = (require ::('LibXML::DocumentFragment')).parse: :balanced, :$string;
    self.appendChild( $frag );
}

method requireNamespace(Str:D $uri where .so --> NCName) {
    $.lookupNamespacePrefix($uri)
    // do {
        my NCName:D $prefix = self.raw.genNsPrefix;
        $.setNamespace($uri, $prefix, :!activate)
            && $prefix
    }
}

method validate() { self.ownerDocument.validate(self) }
method is-valid() { self.ownerDocument.is-valid(self) }

=begin pod


    =head3 method namespaces

          method namespaces() returns LibXML::Node::List
          my LibXML::Namespace @ns = $node.namespaces;

    Returns a list of Namespace declarations for the node. It can be used to iterate through an element's namespaces:

      for $elem.namespaces -> LibXML::Namespace $ns { ... }

    =head3 method appendWellBalancedChunk

        method appendWellBalancedChunk( Str $chunk ) returns LibXML::Node

    Sometimes it is necessary to append a string coded XML Tree to a node. I<appendWellBalancedChunk> will do the trick for you. But this is only done if the String is C<well-balanced>.

    I<Note that appendWellBalancedChunk() is only left for compatibility reasons>. Implicitly it uses

      my LibXML::DocumentFragment $fragment = $parser.parse: :balanced, :$chunk;
      $node.appendChild( $fragment );

    This form is more explicit and makes it easier to control the flow of a script.


    =head3 method appendText

      method appendText( $PCDATA ) returns LibXML::Text

    Alias for appendTextNode().


    =head3 method appendTextNode

      method appendTextNode( $PCDATA ) returns Mu

    This wrapper function lets you add a string directly to an element node.


    =head3 method appendTextChild

      method appendTextChild( QName $childname, $PCDATA ) returns LibXML::Element;

    Somewhat similar with C<appendTextNode>: It lets you set an Element, that contains only a C<text node> directly by specifying the name and the text content.

    =head3 method setNamespace

      method setNamespace( Str $nsURI, NCName $nsPrefix?, :$activate );

    setNamespace() allows one to apply a namespace to an element. The function
    takes a namespace URI, and an optional namespace prefix. If
    prefix is not given, undefined or empty, this function reuses any existing
    definition, in the element's scope, or generates a new prefix.

    The :activate option is most useful: If this parameter is set to False, a
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

    results in:
      =begin code :lang<xml>
      <foo:bar xmlns:foo="http://foobar.org"/>
      =end code
    while:

      my $e2 = $doc.createElement("bar");
      $e2.setNamespace("http://foobar.org", "foo", :!activate)

    results in:
      =begin code :lang<xml>
      <bar xmlns:foo="http://foobar.org"/>
      =end code
    By using :!activate it is possible to create multiple namespace
    declarations on a single element.

    The function fails if it is required to create a declaration associating the
    prefix with the namespace URI but the element already carries a declaration
    with the same prefix but different namespace URI. 


    =head3 method requireNamespace

       use LibXML::Types ::NCName;
       method requireNamespace(Str $uri) returns NCName

    Return the prefix for any any existing namespace in the node's scope that
    matches the URL. If not found, a new namespace is created for the URI
    on the node with an anonymous prefix (_ns0, _ns1, ...).

    =head3 method setNamespaceDeclURI

      method setNamespaceDeclURI( NCName $nsPrefix, Str $newURI ) returns Bool

    This function is NOT part of any DOM API.

    This function manipulates directly with an existing namespace declaration on an
    element. It takes two parameters: the prefix by which it looks up the namespace
    declaration and a new namespace URI which replaces its previous value.

    It returns True if the namespace declaration was found and changed, False otherwise.

    All elements and attributes (even those previously unbound from the document)
    for which the namespace declaration determines their namespace belong to the
    new namespace after the change.  For example:

      my LibXML::Element $elem = .root()
          given LibXML.parse('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>');
      $elem.setNamespaceDeclURI( 'xxx', 'http://ns2.com'  );
      say $elem.Str; # <Doc xmlns:xxx="http://ns2.com"><xxx:elem/></Doc>

    If the new URI is undefined or empty, the nodes have no namespace and no prefix
    after the change. Namespace declarations once nulled in this way do not further
    appear in the serialized output (but do remain in the document for internal
    integrity of libxml2 data structures). 

    =head3 method setNamespaceDeclPrefix

      method setNamespaceDeclPrefix( NCName $oldPrefix, NCName $newPrefix ) returns Bool

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
    prefix to the new value. For example:

      my $node = .root()
          given LibXML.parse('<Doc xmlns:xxx="http://ns.com"><xxx:elem/></Doc>');
      $node.setNamespaceDeclPrefix( 'xxx', 'yyy' );
      say $node.Str; # <Doc xmlns:yyy="http://ns.com"><yyy:elem/></Doc>

    If the new prefix is undefined or empty, the namespace declaration becomes a
    declaration of a default namespace. The corresponding nodes drop their
    namespace prefix (but remain in the, now default, namespace). In this case the
    function fails, if the containing element is in the scope of another default
    namespace declaration. 


=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
