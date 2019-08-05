class LibXML::Node {
    use Method::Also;
    use NativeCall;

    use LibXML::Native;
    use LibXML::Native::DOM::Node;
    use LibXML::Config;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::XPath::Expression;
    use LibXML::Types :NCName, :QName;

    constant config = LibXML::Config;
    my subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;
    my subset NodeSetElem is export(:NodeSetElem) where LibXML::Node|LibXML::Namespace;
    enum <SkipBlanks KeepBlanks>;

    has LibXML::Node $.doc;

    has domNode $.native is rw handles <
        domCheck domFailure
        hasChildNodes
        getNodeName getNodeValue
        lookupNamespacePrefix lookupNamespaceURI
        nodePath
        setNamespaceDeclURI setNamespaceDeclPrefix setNodeName setNodeValue
        unique-key lock unlock
    >;

    BEGIN {
        # wrap methods that return raw nodes
        # simple navigation; no arguments
        # todo: migrate to LibXML::_DOMNode
        for <
             firstChild firstNonBlankChild
             next nextSibling nextNonBlankSibling
             prev previousSibling previousNonBlankSibling
        > {
            $?CLASS.^add_method($_, method { LibXML::Node.box: $!native."$_"() });
        }
        for <replaceNode addSibling> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $new) { LibXML::Node.box( $!native."$_"($new.native)); });
        }
        # single node argument unconstructed
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method(
                $_, method (LibXML::Node:D $node, LibXML::Node $ref) {
                    $node.keep: $!native."$_"($node.native, do with $ref {.native} // domNode);
                });
        }
    }

    method protect(&action) {
        self.lock // die "couldn't get lock";
        my $rv = try { &action(); }
        self.unlock;
        die $_ with $!;
        $rv;
    }
    method isSame(LibXML::Node:D $other) is also<isSameNode> {
        $!native.isSameNode($other.native);
    }
    method isEqual(|c) is DEPRECATED<isSameNode> { $.isSameNode(|c) }
    method ownerElement is also<getOwnerElement parent parentNode> {
        LibXML::Node.box: $!native.parent;
    }
    method last is also<lastChild> {
        LibXML::Node.box: self.native.last;
    }
    method appendChild(LibXML::Node:D $new) is also<addChild> {
        $new.keep: $!native.appendChild($new.native);
    }
    method replaceChild(LibXML::Node $new, LibXML::Node $node) {
        $node.keep: $!native.replaceChild($new.native, $node.native),
    }
    method appendText(Str:D $text) is also<appendTextNode> {
        $!native.appendText($text);
    }

    method native is rw {
        Proxy.new(
            FETCH => { with self {$!native} else {domNode} },
            STORE => -> $, domNode:D $new-struct {
                given box-class($new-struct.type) -> $class {
                    die "mismatch between DOM node of type {$new-struct.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                        unless $class ~~ self.WHAT|LibXML::Namespace;
                }
                .remove-reference with $!native;
                .Reference with $new-struct;
                $!native = cast-struct($new-struct);
            },
        );
    }

    submethod TWEAK {
        .Reference with $!native;
    }

    method setOwnerDocument( LibXML::Node $doc) {
        with $doc {
            unless ($!doc && $doc.isSameNode($!doc)) || $doc.isSameNode(self) {
                $doc.adoptNode(self);
            }
        }
        $!doc = $doc;
    }

    method getOwnerDocument {
        do with self {
            with .native.doc -> xmlDoc $struct {
                $!doc = box-class(XML_DOCUMENT_NODE).box($struct)
                    if ! ($!doc && !$!doc.native.isSameNode($struct));
            }
            else {
                $!doc = Nil;
            }
            $!doc;
        } // (require ::('LibXML::Document'));
    }

    method doc is rw is also<ownerDocument getOwner> {
        Proxy.new(
            FETCH => {
                self.getOwnerDocument;
            },
            STORE => sub ($, LibXML::Node $doc) {
                self.setOwnerDocument($doc);
            },
        );
    }

    method nodeType { $!native.type }

    method getName { self.getNodeName }
    method nodeName is rw is also<name tagName> {
        Proxy.new(
            FETCH => sub ($) { self.getNodeName },
            STORE => sub ($, QName $_) { self.setNodeName($_) },
        );
    }

    method nodeValue is rw {
        Proxy.new(
            FETCH => sub ($) { self.getNodeValue },
            STORE => sub ($, Str() $_) { self.setNodeValue($_) },
        );
    }

    method localname     { $!native.name }
    method line-number   { $!native.GetLineNo }
    method prefix        { do with $!native.ns {.prefix} // Str }
    method getFirstChild { $.firstChild }
    method getLastChild  { $.lastChild }

    sub box-class(UInt $_) is export(:box-class) {
        when XML_ATTRIBUTE_NODE     { require LibXML::Attr }
        when XML_ATTRIBUTE_DECL     { require LibXML::AttrDecl }
        when XML_CDATA_SECTION_NODE { require LibXML::CDATA }
        when XML_COMMENT_NODE       { require LibXML::Comment }
        when XML_DTD_NODE           { require LibXML::Dtd }
        when XML_DOCUMENT_FRAG_NODE { require LibXML::DocumentFragment }
        when XML_DOCUMENT_NODE
           | XML_HTML_DOCUMENT_NODE { require LibXML::Document }
        when XML_ELEMENT_NODE       { require LibXML::Element }
        when XML_ELEMENT_DECL       { require LibXML::ElementDecl }
        when XML_ENTITY_DECL        { require LibXML::EntityDecl }
        when XML_ENTITY_REF_NODE    { require LibXML::EntityRef }
        when XML_NAMESPACE_DECL     { require LibXML::Namespace }
        when XML_PI_NODE            { require LibXML::PI }
        when XML_TEXT_NODE          { require LibXML::Text }

        default {
            warn "node content-type not yet handled: $_";
            LibXML::Node;
        }
    }

    proto sub native($) is export(:native) {*}
    multi sub native(LibXML::XPath::Expression:D $_) { .native }
    multi sub native(LibXML::Node:D $_) { .native }
    multi sub native(LibXML::Namespace:D $_) { .native }
    multi sub native($_) is default  { $_ }

    our sub cast-struct(domNode:D $struct is raw) {
        my $delegate := do given $struct.type {
            when XML_ATTRIBUTE_NODE     { xmlAttr }
            when XML_ATTRIBUTE_DECL     { xmlAttrDecl }
            when XML_CDATA_SECTION_NODE { xmlCDataNode }
            when XML_COMMENT_NODE       { xmlCommentNode }
            when XML_DOCUMENT_FRAG_NODE { xmlDocFrag }
            when XML_DTD_NODE           { xmlDtd }
            when XML_DOCUMENT_NODE      { xmlDoc }
            when XML_HTML_DOCUMENT_NODE { htmlDoc }
            when XML_ELEMENT_NODE       { xmlNode }
            when XML_ELEMENT_DECL       { xmlElementDecl }
            when XML_ENTITY_DECL        { xmlEntityDecl }
            when XML_ENTITY_REF_NODE    { xmlEntityRefNode }
            when XML_NAMESPACE_DECL     { xmlNs }
            when XML_PI_NODE            { xmlPINode }
            when XML_TEXT_NODE          { xmlTextNode }
            default {
                warn "node content-type not yet handled: $_";
                domNode;
            }
        }

        nativecast( $delegate, $struct);
    }

    proto sub cast-elem($ is raw) is export(:cast-elem) {*}
    multi sub cast-elem(xmlNodeSetElem:D $elem is raw) {
        $elem.type == XML_NAMESPACE_DECL
            ?? nativecast(xmlNs, $elem)
            !! cast-struct( nativecast(domNode, $elem) );
    }
    multi sub cast-elem(Pointer $p is raw) is default { cast-elem(nativecast(xmlNodeSetElem, $p)) }

    method box(LibXML::Native::DOM::Node $struct,
               LibXML::Node :$doc = $.doc, # reusable document object
              ) {
        do with $struct {
            my $class := box-class(.type);
            die "mismatch between DOM node of type {.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                    unless $class ~~ self.WHAT|LibXML::Namespace;
            $class.new: :native(cast-struct($_)), :$doc;
        } // self.WHAT; 
    }
    method unbox { $.native }

    method keep(LibXML::Native::DOM::Node $rv,
                LibXML::Node :$doc = $.doc, # reusable document object
                --> LibXML::Node) {
        do with $rv {
            do with self -> $obj {
                die "returned unexpected node: {$.Str}"
                    unless native($obj).isSameNode($_);
                $obj;
            } // self.box: $_, :$doc;
        } // self.WHAT;
    }

    sub iterate-list($parent, $of, domNode $native, :$doc = $of.doc, Bool :$keep-blanks = True) is export(:iterate-list) {
        # follow a chain of .next links.
        (require ::('LibXML::Node::List')).new: :$of, :$native, :$doc, :$keep-blanks, :$parent;
    }

    sub iterate-set($of, xmlNodeSet $native) is export(:iterate-set) {
        # iterate through a set of nodes
        (require ::('LibXML::Node::Set')).new( :$native, :$of )
    }

    method string-value is also<textContent to-literal> {
        $!native.string-value;
    }
    method unlink is also<unlinkNode unbindNode> {
        $!native.Unlink;
        $!doc = LibXML::Node;
        self;
    }
    method childNodes is also<getChildnodes> handles <AT-POS ASSIGN-POS elems List list pairs keys values map grep push pop> {
        iterate-list(self, LibXML::Node, $!native.first-child(KeepBlanks));
    }
    method nonBlankChildNodes {
        iterate-list(self, LibXML::Node, $!native.first-child(SkipBlanks), :!keep-blanks);
    }
    multi method findnodes(LibXML::XPath::Expression:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $!native.findnodes: native($xpath-expr);
        iterate-set(NodeSetElem, $node-set);
    }
    multi method findnodes(Str:D $expr) {
        self.findnodes( LibXML::XPath::Expression.new: :$expr);
    }
    method !select(xmlXPathObject $native, Bool :$values) {
        my $object = (require ::('LibXML::XPath::Object')).new: :$native;
        $object.select: :$values;
    }
    multi method find(LibXML::XPath::Expression:D $xpath-expr, Bool:D :$bool = False, Bool :$values) {
        self!select: $!native.find( native($xpath-expr), :$bool);
    }
    multi method find(Str:D $expr, |c) {
        self.find( LibXML::XPath::Expression.parse($expr), |c);
    }
    multi method findvalue(LibXML::XPath::Expression:D $xpath-expr) {
        $.find( $xpath-expr, :values);
    }
    multi method findvalue(Str:D $expr) {
        $.findvalue( LibXML::XPath::Expression.parse($expr));
    }
    my subset XPathExpr where LibXML::XPath::Expression|Str|Any:U;

    method exists(XPathExpr:D $xpath-expr --> Bool:D) {
        $.find($xpath-expr, :bool);
    }
    method addNamespace(Str $uri, NCName $prefix?) {
        $.setNamespace($uri, $prefix, :!primary);
    }
    method setNamespace(Str $uri, NCName $prefix?, Bool :$activate = True) {
        $!native.setNamespace($uri, $prefix, :$activate);
    }
    method localNS {
        LibXML::Namespace.box: $!native.localNS;
    }
    method getNamespaces is also<namespaces> {
        $!native.getNamespaces.map: { LibXML::Namespace.box($_) }
    }
    method getNamespaceURI(--> Str) is also<namespaceURI> { do with $!native.ns {.href} // Str }
    method removeChild(LibXML::Node:D $node --> LibXML::Node) {
        $node.keep: $!native.removeChild($node.native), :doc(LibXML::Node);
    }
    method removeChildNodes(--> LibXML::Node) {
        LibXML::Node.box: $!native.removeChildNodes, :doc(LibXML::Node);
    }
    multi method appendTextChild(NameVal:D $_) {
        $!native.appendTextChild(.key, .value);
    }
    multi method appendTextChild(QName:D $name, Str $value?) {
        $!native.appendTextChild($name, $value);
    }
    method addNewChild(Str $uri, QName $name) {
        LibXML::Node.box: $!native.domAddNewChild($uri, $name);
    }
    method normalise is also<normalize> { self.native.normalize }
    method clone(LibXML::Node:D: Bool() :$deep = False) is also<cloneNode> {
        LibXML::Node.box: $!native.cloneNode($deep), :doc(LibXML::Node);
    }

    multi method save(IO::Handle :$io!, Bool :$format = False) {
        $io.write: self.Blob(:$format);
    }

    multi method save(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :w);
        $.save(:$io, |c);
        $io;
    }

    multi method save(IO() :file($io)!, |c) {
        $.save(:$io, |c).close;
    }

    sub output-options(UInt :$options is copy = 0,
                       Bool :$format,
                       Bool :$skip-decl = config.skip-xml-declaration,
                       Bool :$expand = config.tag-expansion,
                      ) is export(:output-options) {

        $options +|= XML_SAVE_FORMAT
            if $format;
        $options +|= XML_SAVE_NO_DECL
            if $skip-decl;
        $options +|= XML_SAVE_NO_EMPTY
           if $expand;

        $options;
    }

    method !c14n-str(Bool() :$comments,
                     Bool() :$exclusive = False,
                     Version :$v = v1.0,
                     XPathExpr :$xpath is copy,
                     :$selector = self,
                     :@prefix,
                     UInt :$mode = $v >= v1.1
                          ?? XML_C14N_1_1
                          !! ($exclusive ?? XML_C14N_EXCLUSIVE_1_0 !! XML_C14N_1_0),
                     --> Str
                    ) {
        my Str $rv;
        my CArray[Str] $prefix .= new: |@prefix, Str;

        if self.defined {
            if $.nodeType !~~ XML_DOCUMENT_NODE|XML_HTML_DOCUMENT_NODE|XML_DOCB_DOCUMENT_NODE {
                ## due to how c14n is implemented, the nodeset it receives must
                ## include child nodes; ie, child nodes aren't assumed to be rendered.
                ## so we use an xpath expression to find all of the child nodes.
                state $AllNodes //= LibXML::XPath::Expression.new: expr => '(. | .//node() | .//@* | .//namespace::*)';
                state $NonCommentNodes //= LibXML::XPath::Expression.new: expr => '(. | .//node() | .//@* | .//namespace::*)[not(self::comment())]';
                $xpath //= $comments ?? $AllNodes !! $NonCommentNodes;
            }
            my $nodes = $selector.findnodes($_)
                with $xpath;

            $rv := $!native.xml6_node_to_str_C14N(
                +$comments, $mode, $prefix,
                do with $nodes { .native } else { xmlNodeSet },
            );

            die $_ with $.domFailure;
        }
        $rv;
    }

    method getBaseURI { $!native.GetBase }
    method setBaseURI(Str() $uri) { $!native.SetBase($uri) }
    method baseURI is rw is also<URI> {
        Proxy.new(
            FETCH => sub ($) { self.getBaseURI },
            STORE => sub ($, Str() $uri) { self.setBaseURI($uri) }
        );
    }

    proto method Str(|) is also<serialize> {*}
    multi method Str(:$C14N! where .so, |c) {
        self!c14n-str(|c);
    }
    multi method Str(|c) is default {
        my $options = output-options(|c);
        $!native.Str(:$options);
    }

    method Blob(Str :$enc, |c) {
        my $options = output-options(|c);
        $!native.Blob(:$enc, :$options);
    }

    submethod DESTROY {
        .Unreference with $!native;
    }
}

=begin pod
=head1 NAME

LibXML::Node - Abstract Base Class of LibXML Nodes

=head1 SYNOPSIS



  use LibXML::Node;

  my LibXML::Node $node;
  my Str $name = $node.nodeName;
  $node.nodeName = $newName;
  my Bool $same = $node.isSame( $other-node );
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
  my LibXML::Node @found = $node.findnodes( $xpath-expression );
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


=head1 DESCRIPTION

LibXML::Node defines functions that are common to all Node Types. An
LibXML::Node should never be created standalone, but as an instance of a high
level class such as LibXML::Element or LibXML::Text. The class itself should
provide only common functionality. In LibXML each node is part either of a
document or a document-fragment. Because of this there is no node without a
parent. This may causes confusion with "unbound" nodes.


=head1 METHODS

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation. 

=begin item1
nodeName

  my Str $name = $node.nodeName;

Returns the node's name. This function is aware of namespaces and returns the
full name of the current node (C<<<<<< prefix:localname >>>>>>). 

Since 1.62 this function also returns the correct DOM names for node types with
constant names, namely: #text, #cdata-section, #comment, #document,
#document-fragment. 

=end item1

=begin item1
setNodeName

  $node.setNodeName( $newName );
  $node.nodeName = $newName;

In very limited situations, it is useful to change a nodes name. In the DOM
specification this should throw an error. This Function is aware of namespaces.

=end item1

=begin item1
isSameNode

  my Bool $is-same = $node.isSameNode( $other_node );

returns True if the given nodes refer to the same node structure, otherwise
False is returned.

=end item1

=begin item1
unique-key

  my Str $key = $node.unique-key;

This function is not specified for any DOM level. It returns a key guaranteed
to be unique for this node, and to always be the same value for this node. In
other words, two node objects return the same key if and only if isSameNode
indicates that they are the same node.

The returned key value is useful as a key in hashes.

=end item1

=begin item1
nodeValue

  my Str $content = $node.nodeValue;

If the node has any content (such as stored in a C<<<<<< text node >>>>>>) it can get requested through this function.

I<<<<<< NOTE: >>>>>> Element Nodes have no content per definition. To get the text value of an
Element use textContent() instead!

=end item1

=begin item1
textContent

  my Str $content = $node.textContent;

this function returns the content of all text nodes in the descendants of the
given node as specified in DOM.

=end item1

=begin item1
nodeType

  my UInt $type = $node.nodeType;

Return a numeric value representing the node type of this node. The module
LibXML by default exports constants for the node types (see the EXPORT section
in the L<<<<<< LibXML >>>>>> manual page).

=end item1

=begin item1
unbindNode

  $node.unbindNode();

Unbinds the Node from its siblings and Parent, but not from the Document it
belongs to. If the node is not inserted into the DOM afterwards, it will be
lost after the program terminates. From a low level view, the unbound node is
stripped from the context it is and inserted into a (hidden) document-fragment.

=end item1

=begin item1
removeChild

  my LibXML::Node $child = $node.removeChild( $node );

This will unbind the Child Node from its parent C<<<<<< $node >>>>>>. The function returns the unbound node. If C<<<<<< oldNode >>>>>> is not a child of the given Node the function will fail.

=end item1

=begin item1
replaceChild

  $oldnode = $node.replaceChild( $newNode, $oldNode );

Replaces the C<<<<<< $oldNode >>>>>> with the C<<<<<< $newNode >>>>>>. The C<<<<<< $oldNode >>>>>> will be unbound from the Node. This function differs from the DOM L2
specification, in the case, if the new node is not part of the document, the
node will be imported first.

=end item1

=begin item1
replaceNode

  $node.replaceNode($newNode);

This function is very similar to replaceChild(), but it replaces the node
itself rather than a childnode. This is useful if a node found by any XPath
function, should be replaced.

=end item1

=begin item1
appendChild

  $childnode = $node.appendChild( $childnode );

The function will add the C<<<<<< $childnode >>>>>> to the end of C<<<<<< $node >>>>>>'s children. The function should fail, if the new childnode is already a child
of C<<<<<< $node >>>>>>. This function differs from the DOM L2 specification, in the case, if the new
node is not part of the document, the node will be imported first.

=end item1

=begin item1
addChild

  $childnode = $node.addChild( $childnode );

This is alias for appendChild (unlike Perl 5 which binds this to xmlAddChild()).

=end item1

=begin item1
addNewChild

  $node = $parent.addNewChild( $nsURI, $name );

Similar to C<<<<<< addChild() >>>>>>, this function uses low level libxml2 functionality to provide faster
interface for DOM building. I<<<<<< addNewChild() >>>>>> uses C<<<<<< xmlNewChild() >>>>>> to create a new node on a given parent element.

addNewChild() has two parameters $nsURI and $name, where $nsURI is an
(optional) namespace URI. $name is the fully qualified element name;
addNewChild() will determine the correct prefix if necessary.

The function returns the newly created node.

This function is very useful for DOM building, where a created node can be
directly associated with its parent. I<<<<<< NOTE >>>>>> this function is not part of the DOM specification and its use will limit your
code to LibXML.

=end item1

=begin item1
addSibling

  $node.addSibling($newNode);

addSibling() allows adding an additional node to the end of a nodelist, defined
by the given node.

=end item1

=begin item1
cloneNode

  $newnode = $node.cloneNode( $deep );

I<<<<<< cloneNode >>>>>> creates a copy of C<<<<<< $node >>>>>>. When $deep is set to 1 (true) the function will copy all child nodes as well.
If $deep is 0 only the current node will be copied. Note that in case of
element, attributes are copied even if $deep is 0. 

Note that the behavior of this function for $deep=0 has changed in 1.62 in
order to be consistent with the DOM spec (in older versions attributes and
namespace information was not copied for elements).

=end item1

=begin item1
parentNode

  my LibXML::Node $parent = $node.parentNode;

Returns simply the Parent Node of the current node.

=end item1

=begin item1
nextSibling

  my LibXML::Node $next = $node.nextSibling();

Returns the next sibling if any .

=end item1

=begin item1
nextNonBlankSibling

  my LibXML::Node $next = $node.nextNonBlankSibling();

Returns the next non-blank sibling if any (a node is blank if it is a Text or
CDATA node consisting of whitespace only). This method is not defined by DOM.

=end item1

=begin item1
previousSibling

  my LibXML::Node $prev = $node.previousSibling();

Analogous to I<<<<<< getNextSibling >>>>>> the function returns the previous sibling if any.

=end item1

=begin item1
previousNonBlankSibling

  my LibXML::Node $prev = $node.previousNonBlankSibling();

Returns the previous non-blank sibling if any (a node is blank if it is a Text
or CDATA node consisting of whitespace only). This method is not defined by
DOM.

=end item1

=begin item1
hasChildNodes

  my Bool $has-kids = $node.hasChildNodes();

If the current node has child nodes this function returns True, otherwise
it returns False.

=end item1

=begin item1
firstChild

  my LibXML::Node $child = $node.firstChild;

If a node has child nodes this function will return the first node in the child
list.

=end item1

=begin item1
lastChild

  my LibXML::Node $child = $node.lastChild;

If the C<<<<<< $node >>>>>> has child nodes this function returns the last child node.

=end item1

=begin item1
ownerDocument

  my LibXML::Document $doc = $node.ownerDocument;

Through this function it is always possible to access the document the current
node is bound to.

=end item1

=begin item1
getOwner

  my LibXML::Node $owner = $node.getOwner;

This function returns the node the current node is associated with. In most
cases this will be a document node or a document fragment node.

=end item1

=begin item1
setOwnerDocument

  $node.setOwnerDocument( $doc );
  $node.ownerDocument = doc;

This function binds a node to another DOM. This method unbinds the node first,
if it is already bound to another document.

This function is the opposite calling of L<<<<<< LibXML::Document >>>>>>'s adoptNode() function. Because of this it has the same limitations with
Entity References as adoptNode().

=end item1

=begin item1
insertBefore

  $node.insertBefore( $newNode, $refNode );

The method inserts C<<<<<< $newNode >>>>>> before C<<<<<< $refNode >>>>>>. If C<<<<<< $refNode >>>>>> is undefined, the newNode will be set as the new last child of the parent node.
This function differs from the DOM L2 specification, in the case, if the new
node is not part of the document, the node will be imported first,
automatically.

$refNode has to be passed to the function even if it is undefined:



  $node.insertBefore( $newNode, undef ); # the same as $node.appendChild( $newNode );
   $node.insertBefore( $newNode ); # wrong

Note, that the reference node has to be a direct child of the node the function
is called on. Also, $newChild is not allowed to be an ancestor of the new
parent node.

=end item1

=begin item1
insertAfter

  $node.insertAfter( $newNode, $refNode );

The method inserts C<<<<<< $newNode >>>>>> after C<<<<<< $refNode >>>>>>. If C<<<<<< $refNode >>>>>> is undefined, the newNode will be set as the new last child of the parent node.

Note, that $refNode has to be passed explicitly even if it is undef.

=end item1

=begin item1
findnodes

  my LibXML::Node @nodes = $node.findnodes( $xpath-expression );
  my LibXML::Node::Set $nodes = $node.findnodes( $xpath-expression );

I<<<<<< findnodes >>>>>> evaluates the xpath expression (XPath 1.0) on the current node and returns the
resulting node set as an array. In scalar context, returns an L<<<<<< LibXML::NodeList >>>>>> object.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

I<<<<<< NOTE ON NAMESPACES AND XPATH >>>>>>:

A common mistake about XPath is to assume that node tests consisting of an
element name with no prefix match elements in the default namespace. This
assumption is wrong - by XPath specification, such node tests can only match
elements that are in no (i.e. null) namespace. 

So, for example, one cannot match the root element of an XHTML document with C<<<<<< $node-&gt;find('/html') >>>>>> since C<<<<<< '/html' >>>>>> would only match if the root element C<<<<<< &lt;html&gt; >>>>>> had no namespace, but all XHTML elements belong to the namespace
http://www.w3.org/1999/xhtml. (Note that C<<<<<< xmlns="..." >>>>>> namespace declarations can also be specified in a DTD, which makes the
situation even worse, since the XML document looks as if there was no default
namespace). 

There are several possible ways to deal with namespaces in XPath: 

=item2 * The recommended way is to use the L<<<<<< LibXML::XPathContext >>>>>> module to define an explicit context for XPath evaluation, in which a document
independent prefix-to-namespace mapping can be defined. For example: 



  my $xpc = LibXML::XPathContext.new;
  $xpc.registerNs('x', 'http://www.w3.org/1999/xhtml');
  $xpc.find('/x:html', $node);

=item2 * Another possibility is to use prefixes declared in the queried document (if
known). If the document declares a prefix for the namespace in question (and
the context node is in the scope of the declaration), C<<<<<< LibXML >>>>>> allows you to use the prefix in the XPath expression, e.g.: 



  $node.find('/x:html');

See also LibXML::XPathContext.findnodes.

=end item1

=begin item1
find

  $result = $node.find( $xpath );

I<<<<<< find >>>>>> evaluates the XPath 1.0 expression using the current node as the context of the
expression, and returns the result depending on what type of result the XPath
expression had. For example, the XPath "1 * 3 + 52" results in a L<<<<<< LibXML::Number >>>>>> object being returned. Other expressions might return an L<<<<<< Bool >>>>>> object, Numeric, or a L<<<<<< Str >>>>>> object. Each of those objects uses Perl's overload feature to "do
the right thing" in different contexts.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

See also L<<<<<< LibXML::XPathContext >>>>>>.find.

=end item1

=begin item1
findvalue

  print $node.findvalue( $xpath );

I<<<<<< findvalue >>>>>> is exactly equivalent to:



  $node.find( $xpath ).to-literal;

That is, it returns the literal value of the results. This enables you to
ensure that you get a string back from your search, allowing certain shortcuts.
This could be used as the equivalent of XSLT's <xsl:value-of
select="some_xpath"/>.

See also L<<<<<< LibXML::XPathContext >>>>>>.findvalue.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

=end item1

=begin item1
exists

  my Bool $found = $node.exists( $xpath_expression );

This method behaves like I<<<<<< findnodes >>>>>>, except that it only returns a boolean value (1 if the expression matches a
node, 0 otherwise) and may be faster than I<<<<<< findnodes >>>>>>, because the XPath evaluation may stop early on the first match (this is true
for libxml2 >= 2.6.27). 

For XPath expressions that do not return node-set, the method returns true if
the returned value is a non-zero number or a non-empty string.

=end item1

=begin item1
childNodes

  my LibXML::Node @kids = $node.childNodes();
  my LibXML::Node::List $kids = $node.childNodes();

I<<<<<< childNodes >>>>>> implements a more intuitive interface to the childnodes of the current node. It
enables you to pass all children directly to a C<<<<<< map >>>>>> or C<<<<<< grep >>>>>>. If this function is called in scalar context, a L<<<<<< LibXML::NodeList >>>>>> object will be returned.

=end item1

=begin item1
nonBlankChildNodes

  my LibXML::Node @kids = $node.nonBlankChildNodes();
  my LibXML::Node::List $kids = $node.nonBlankChildNodes();

This is like I<<<<<< childNodes >>>>>>, but returns only non-blank nodes (where a node is blank if it is a Text or
CDATA node consisting of whitespace only). This method is not defined by DOM.

=end item1

=begin item1
Str

  my Str $xml = $node.String(:format);

This method is similar to the method C<<<<<< Str >>>>>> of a L<<<<<< LibXML::Document >>>>>> but for a single node. It returns a string consisting of XML serialization of
the given node and all its descendants. Unlike C<<<<<< LibXML::Document::Str >>>>>>.

=end item1

=begin item1
Str: :C14N

  my Str $xml-c14 = $node.Str: :C14N;
  $c14nstring = $node.String, :C14N, :comments, :xpath($xpath-expression);

The function is similar to Str(). Instead of simply serializing the
document tree, it transforms it as it is specified in the XML-C14N
Specification (see L<<<<<< http://www.w3.org/TR/xml-c14n >>>>>>). Such transformation is known as canonization.

If :$comments is False or not specified, the result-document will not contain any
comments that exist in the original document. To include comments into the
canonized document, :$comments has to be set to True.

The parameter :$xpath defines the nodeset of nodes that should be
visible in the resulting document. This can be used to filter out some nodes.
One has to note, that only the nodes that are part of the nodeset, will be
included into the result-document. Their child-nodes will not exist in the
resulting document, unless they are part of the nodeset defined by the xpath
expression. 

If :$xpath is omitted or empty, Str: :C14N will include all nodes
in the given sub-tree, using the following XPath expressions: with comments 

  (. | .//node() | .//@* | .//namespace::*)

and without comments 

  (. | .//node() | .//@* | .//namespace::*)[not(self::comment())]



An optional parameter :$selector can be used to pass an L<<<<<< LibXML::XPathContext >>>>>> object defining the context for evaluation of $xpath-expression. This is useful
for mapping namespace prefixes used in the XPath expression to namespace URIs.
Note, however, that $node will be used as the context node for the evaluation,
not the context node of :$selector. 

=end item1

=begin item1
Str: :C14N, :v(v1.1)

  $c14nstring = $node.Str: :C14N, :v(v1.1);
  $c14nstring = $node.String: :C14N, :v(v1.1), :comments, :xpath($expression) , :selector($context);

This function behaves like Str: :C14N except that it uses the
"XML_C14N_1_1" constant for canonicalising using the "C14N 1.1 spec". 

=end item1

=begin item1
Str: :C14N, :exclusive

  $ec14nstring = $node.Str: :C14N, :exclusive;
  $ec14nstring = $node.Str: :C14N, :exclusive, :$comments, :xpath($expression), :prefix(@inclusive-list);

The function is similar to Str: :C14N but follows the XML-EXC-C14N
Specification (see L<<<<<< http://www.w3.org/TR/xml-exc-c14n >>>>>>) for exclusive canonization of XML.

The arguments :comments, :$xpath, :$selector are as in
Str: :C14N. :@prefix is a list of namespace prefixes that are to be handled in
the manner described by the Canonical XML Recommendation (i.e. preserved in the
output even if the namespace is not used). C.f. the spec for details. 

=end item1

=begin item1
serialize

  my Str $xml = $doc.serialize($format); 

An alias for Str. This function was name added to be more consistent
with libxml2.

=end item1

=begin item1
serialize-c14n

An alias for Str: :C14N.

=end item1

=begin item1
serialize-exc-c14n

An alias for Str: :C14N, :exclusive

=end item1

=begin item1
localname

  my Str $localname = $node.localname;

Returns the local name of a tag. This is the part behind the colon.

=end item1

=begin item1
prefix

  my Str $prefix = $node.prefix;

Returns the prefix of a tag. This is the part before the colon.

=end item1

=begin item1
namespaceURI

  my Str $uri = $node.namespaceURI();

returns the URI of the current namespace.

=end item1

=begin item1
lookupNamespaceURI

  $URI = $node.lookupNamespaceURI( $prefix );

Find a namespace URI by its prefix starting at the current node.

=end item1

=begin item1
lookupNamespacePrefix

  $prefix = $node.lookupNamespacePrefix( $URI );

Find a namespace prefix by its URI starting at the current node.

I<<<<<< NOTE >>>>>> Only the namespace URIs are meant to be unique. The prefix is only document
related. Also the document might have more than a single prefix defined for a
namespace.

=end item1

=begin item1
normalize

  $node.normalize;

This function normalizes adjacent text nodes. This function is not as strict as
libxml2's xmlTextMerge() function, since it will not free a node that is still
referenced by the perl layer.

=end item1

=begin item1
getNamespaces

  my LibXML::Namespace @ns = $node.getNamespaces;

If a node has any namespaces defined, this function will return these
namespaces. Note, that this will not return all namespaces that are in scope,
but only the ones declared explicitly for that node.

Although getNamespaces is available for all nodes, it only makes sense if used
with element nodes.

=end item1

=begin item1
removeChildNodes

  $node.removeChildNodes();

This function is not specified for any DOM level: It removes all childnodes
from a node in a single step. Other than the libxml2 function itself
(xmlFreeNodeList), this function will not immediately remove the nodes from the
memory. This saves one from getting memory violations, if there are nodes still
referred to from the Perl level.

=end item1

=begin item1
baseURI ()

  my Str $URI = $node.baseURI();

Searches for the base URL of the node. The method should work on both XML and
HTML documents even if base mechanisms for these are completely different. It
returns the base as defined in RFC 2396 sections "5.1.1. Base URI within
Document Content" and "5.1.2. Base URI from the Encapsulating Entity". However
it does not return the document base (5.1.3), use method C<<<<<< URI >>>>>> of C<<<<<< LibXML::Document >>>>>> for this. 

=end item1

=begin item1
setBaseURI ($URI)

  $node.setBaseURI($URI);
  $node.baseURI = $URI;

This method only does something useful for an element node in an XML document.
It sets the xml:base attribute on the node to $strURI, which effectively sets
the base URI of the node to the same value. 

Note: For HTML documents this behaves as if the document was XML which may not
be desired, since it does not effectively set the base URI of the node. See RFC
2396 appendix D for an example of how base URI can be specified in HTML. 

=end item1

=begin item1
nodePath

  my Str $path = $node.nodePath();

This function is not specified for any DOM level: It returns a canonical
structure based XPath for a given node.

=end item1

=begin item1
line_number

  my Uint $lineno = $node.line-number();

This function returns the line number where the tag was found during parsing.
If a node is added to the document the line number is 0. Problems may occur, if
a node from one document is passed to another one.

IMPORTANT: Due to limitations in the libxml2 library line numbers greater than
65535 will be returned as 65535. Please see L<<<<<< http://bugzilla.gnome.org/show_bug.cgi?id=325533 >>>>>> for more details. 

Note: linenumber() is special to LibXML and not part of the DOM specification.

If the line-numbers flag of the parser was not activated before parsing,
line-number() will always return 0.

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
