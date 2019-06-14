#| low level unsugared DOM. Works directly on native XML Nodes
unit role LibXML::Native::DOM::Node;
my constant Node = LibXML::Native::DOM::Node;
use LibXML::Enums;
use LibXML::Types :NCName, :QName;
use NativeCall;

method doc { ... }
method type { ... }
method children { ... }
method last { ... }
method find { ... }
method findnodes { ... }
method copy { ... }
method GetNodePath { ... }

method domAppendChild  { ... }
method domAppendTextChild  { ... }
method domReplaceNode  { ... }
method domAddSibling  { ... }
method domReplaceChild  { ... }
method domInsertBefore { ... }
method domInsertAfter  { ... }
method domName { ... }
method domGetNodeValue { ... }
method domSetNodeValue { ... }
method domRemoveChild  { ... }
method domGetAttributeNode { ... }
method domGetAttributeNodeNS { ... }
method domGetAttribute { ... }
method domGetAttributeNS { ... }
method domSetNamespaceDeclPrefix { ... }
method domSetNamespaceDeclURI { ... }
method domGetNamespaceDeclURI { ... }
method domSetAttribute { ... }
method domSetAttributeNode { ... }
method domSetAttributeNodeNS { ... }
method domSetAttributeNS { ... }
method domSetNamespace { ... }
method domGetChildrenByLocalName { ... }
method domGetChildrenByTagName { ... }
method domGetChildrenByTagNameNS { ... }
method domAddNewChild { ... }
method domNormalize { ... }

my constant XML_XMLNS_NS = 'http://www.w3.org/2000/xmlns/';
my constant XML_XML_NS   = 'http://www.w3.org/XML/1998/namespace';
enum <SkipBlanks KeepBlanks>;

method native { self } # already native

method firstChild { self.first-child(KeepBlanks); }
method firstNonBlankChild { self.first-child(SkipBlanks); }

method appendChild(Node $nNode) {
    self.domAppendChild($nNode)
        // self.dom-error // Node;
}

my subset AttrNode of Node where {!.defined || .type == XML_ATTRIBUTE_NODE};

method setAttribute(QName:D $name, Str:D $value) {
    if $name ~~ /^xmlns[\:(.*)|$]/ {
        # user wants to set the special attribute for declaring XML namespace ...

        # this is fine but not exactly DOM conformant behavior, btw (according to DOM we should
        # probably declare an attribute which looks like XML namespace declaration
        # but isn't)
        my NCName $prefix = ($0 // '').Str;
        my QName $nn = self.nodeName;

        if $nn.starts-with($prefix ~ ':') {
	    # the element has the same prefix
	    self.domSetNamespaceDeclURI($prefix, $value)
	    || self.domSetNamespace($value, $prefix, 1);
            ##
            ## We set the namespace here.
            ## This is helpful, as in:
            ##
            ## |  $e = XML::LibXML::Element.new: :name<foo:bar>;
            ## |  $e.setAttribute('xmlns:foo','http://yoyodine')
            ##
        }
        else {
	    # just modify the namespace
	    self.domSetNamespaceDeclURI($prefix, $value)
	    || self.domSetNamespace($value, $prefix, 0);
        }
    }
    else {
        self.domSetAttribute($name, $value);
    }
}

method setAttributeNode(AttrNode $att) {
    self.domSetAttributeNode($att);
}

method setAttributeNodeNS(AttrNode $att) {
    self.domSetAttributeNodeNS($att);
}

method getAttributeNode(QName:D $att-name) {
    self.domGetAttributeNode($att-name);
}

method hasAttribute(Str $att-name --> Bool) {
    self.getAttributeNode($att-name).defined;
}

method hasAttributeNS(Str $uri, Str $att-name --> Bool) {
    ? self.domHasAttributeNS($uri, $att-name);
}

method removeAttribute(Str:D $attr-name) {
    .Release with self.getAttributeNode($attr-name);
}

method removeAttributeNode(AttrNode:D $attr --> Node) {
    if $attr.type == XML_ATTRIBUTE_NODE
    && self.isSameNode($attr.parent) {
        $attr.Unlink;
        $attr;
    }
    else {
        Node;
    }
}

method removeAttributeNS(Str $uri, Str $attr-name) {
    .Release with self.getAttributeNodeNS($uri, $attr-name);
}

method getAttributeNodeNS(Str $uri, QName:D $att-name --> AttrNode) {
    self.domGetAttributeNodeNS($uri, $att-name);
}

method setNamespaceDeclPrefix(NCName $prefix, NCName $new-prefix --> Int) {
    my $rv := self.domSetNamespaceDeclPrefix($prefix, $new-prefix);
    self.dom-error if $rv < 0;
    $rv;
}

method getAttributeNS(Str $uri, QName:D $att-name --> Str) {
    self.domGetAttributeNS($uri, $att-name);
}

method localNS { self.ns }

method nodePath { self.GetNodePath }

method getAttribute(QName:D $name) {
    if $name ~~ /^xmlns[\:(.*)|$]/ {
        # user wants to set the special attribute for declaring XML namespace ...

        # this is fine but not exactly DOM conformant behavior, btw (according to DOM we should
        # probably declare an attribute which looks like XML namespace declaration
        # but isn't)
        my Str:D $prefix = ($0 // '').Str;
        self.domGetNamespaceDeclURI($prefix);
    }
    else {
        self.domGetAttribute($name);
    }
}

method getNamespaceDeclURI(NCName $prefix) {
    self.domGetNamespaceDeclURI($prefix);
}

method setNamespaceDeclURI(NCName $prefix, Str $uri) {
    self.domSetNamespaceDeclURI($prefix, $uri);
}

sub opt(Str $_) { $_ ?? $_ !! Str }

method setAttributeNS(Str $uri, QName:D $name, Str:D $value) {
    if $name ~~ /^xmlns[\:|$]/ {
        if $uri !~~ XML_XMLNS_NS {
            fail("NAMESPACE ERROR: Namespace declarations must have the prefix 'xmlns'");
        }
        self.setAttribute($name, $value); # see implementation above
        self.domGetAttributeNode($name);
    }
    else {
        if $name.contains(':') and not $uri {
            fail("NAMESPACE ERROR: Attribute without a prefix cannot be in a namespace");
        }
        if $uri ~~ XML_XMLNS_NS {
            fail("NAMESPACE ERROR: 'xmlns' prefix and qualified-name are reserved for the namespace "~XML_XMLNS_NS);
        }
        if $name.starts-with('xml:') and not $uri ~~ XML_XML_NS {
            fail("NAMESPACE ERROR: 'xml' prefix is reserved for the namespace "~XML_XML_NS);
        }

        self.domSetAttributeNS($uri, $name, $value);
    }
}

method setNamespace(Str $uri, NCName $prefix, Bool :$primary) {
    self.domSetNamespace($uri, $prefix, $primary);
}

method removeChild(Node:D $child) {
    self.domRemoveChild($child);
}

method replaceChild(Node $child, Node $old) {
    self.domReplaceChild($child, $old)
        // self.dom-error;
}

method addSibling(Node $new) {
    self.domAddSibling($new)
        // self.dom-error;
}

method replaceNode(Node $new) {
    self.domReplaceNode($new)
        // self.dom-error;
}

method !descendants(Str:D $expr = '') {
   self.domXPathSelectStr("descendant::*" ~ $expr);
}

multi method getElementsByTagName('*') {
    self!descendants;
}
multi method getElementsByTagName(Str:D $name) {
    self!descendants: "[name()='$name']";
}

multi method getElementsByLocalName('*') {
    self!descendants;
}
multi method getElementsByLocalName(Str:D $name) {
    self!descendants: "[local-name()='$name']";
}

multi method getElementsByTagNameNS('*','*') {
    self!descendants;
}
multi method getElementsByTagNameNS(Str() $URI, '*') {
    self!descendants: "[namespace-uri()='$URI']";
}
multi method getElementsByTagNameNS('*', Str $name) {
    self!descendants: "[local-name()='$name']";
}
multi method getElementsByTagNameNS(Str() $URI, Str $name) {
    self!descendants: "[local-name()='$name' and namespace-uri()='$URI']";
}

method getChildrenByLocalName(Str $name) {
    self.domGetChildrenByLocalName($name);
}

method getChildrenByTagName(Str $name) {
    self.domGetChildrenByTagName($name);
}

method getChildrenByTagNameNS(Str $URI, Str $name) {
    self.domGetChildrenByTagNameNS($URI, $name);
}

method insertBefore(Node:D $nNode, Node $oNode) {
    self.domInsertBefore($nNode, $oNode)
        // self.dom-error;
}

method insertAfter(Node:D $nNode, Node $oNode) {
    self.domInsertAfter($nNode, $oNode)
        // self.dom-error;
}

method cloneNode(Bool:D $deep) {
    self.copy(:$deep);
}

method nodeName { self.domName; }

method nodeValue is rw {
    Proxy.new(
        FETCH => sub ($) { self.domGetNodeValue },
        STORE => sub ($, Str() $_) { self.domSetNodeValue($_) },
    );
}

method hasAttributes returns Bool {
    ? (self.type != XML_ATTRIBUTE_NODE
       && self.type != XML_DTD_NODE
       && self.properties.defined)
}

method removeChildNodes {
    self.domRemoveChildNodes;
}

method hasChildNodes returns Bool {
    ? (self.type != XML_ATTRIBUTE_NODE && self.children.defined)
}

method nextSibling returns Node { self.next-node(KeepBlanks); }
method nextNonBlankSibling returns Node { self.next-node(SkipBlanks); }

method previousSibling returns Node { self.prev-node(KeepBlanks); }

method previousNonBlankSibling returns Node { self.prev-node(SkipBlanks); }

method appendText(Str:D $text) {
    self.AddContent($text);
}

method appendTextChild(QName:D $name, Str $text) {
    self.domAppendTextChild($name, $text);
}

method lookupNamespacePrefix(Str $uri --> Str) {
    do with self.doc.SearchNsByHref(self, opt($uri)) {
        .prefix // '';
    } // Str;
}

method lookupNamespaceURI(NCName $prefix --> Str) {
    do with self.doc.SearchNs(self, opt($prefix)) {
        .href // '';
    } // Str;
}

method addNewChild(Str $uri, QName $name) {
    self.box: self.domAddNewChild($uri, $name);
}


method normalize { self.domNormalize }

sub addr($d) { (+nativecast(Pointer, $_) with $d) // 0  }

method isSameNode(Node $oNode) {
    addr(self) ~~ addr($oNode);
}

sub oops($node, Bool $ok is rw, @path, Str:D $msg) {
    my $where = '[' ~ @path.join(',') ~ '] ' ~ $node.domName ~ '(' ~ $node.type ~ ')';
    die $where ~ ' : ' ~ $msg;
    $ok = False;
}

method domCheck(Bool :$recursive = True, :%seen = %(), :@path = [0]) {
    # perform various integrity checks on the current node
    # - uniqueness of nodes
    # - parent child links (parent.child === child.parent)
    # - sibling links (prev.next === next.prev)
    # - parent.last == last-sibling
    # - consistant doc entries
    # consider moving to dom.c (profiling/benchmarking needed)

    my Bool $ok = True;
    return (self.type == XML_ENTITY_DECL
            ?? $ok
            !! oops(self, $ok, @path, "duplicate node"))
        if %seen{addr(self)}++;

    my Node $last;
    my Node $kid = self.children;
    my $is-doc = ? (self.type == XML_DOCUMENT_NODE|XML_HTML_DOCUMENT_NODE|XML_DOCB_DOCUMENT_NODE);
    my @subpath = @path;
    @subpath.push: 0;
    my %kids-seen;
    while $kid.defined {
        oops($kid, $ok, @subpath, "inconsistant parent link (" ~ self.type ~ ')')
            if addr($kid.parent) !~~ addr(self)
            && $kid.type != XML_ENTITY_DECL;
        if %kids-seen{addr($kid)}++ {
            oops($kid, $ok, @subpath, "cycle detected in sibling links");
            last;
        }
        if $recursive {
            $ok = False
                unless $kid.domCheck(:%seen, :@subpath);
        }

        my $next = $kid.next;

        @subpath.tail++;
        with $next {
            oops($_, $ok, @subpath, "inconsistant prev link")
                unless addr(.prev) == addr($kid);
        }
        $last = $kid;
        $kid = $next;
    }

    oops(self, $ok, @path, "wrong last link {self.last.Str} => {$last.Str}")
        unless addr(self.last) ~~ addr($last)
        || $last.type == XML_ENTITY_DECL;

    $ok
}

method baseURI is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetBase },
        STORE => sub ($, Str() $uri) { self.SetBase($uri) }
    );
}

