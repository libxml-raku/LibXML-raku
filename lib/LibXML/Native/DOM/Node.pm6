#| low level DOM. Works directly on Native XML Nodes
unit role LibXML::Native::DOM::Node;
my constant Node = LibXML::Native::DOM::Node;
use LibXML::Enums;
use LibXML::Types :NCName, :QName;
use NativeCall;

method doc { ... }
method type { ... }
method children { ... }
method last { ... }

method domError { ... }
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
method domSetAttributeNode { ... }
method domSetAttributeNodeNS { ... }
method domSetAttributeNS { ... }
method domSetNamespace { ... }
method domXPathSelect  { ... }
method domGetChildrenByLocalName { ... }
method domGetChildrenByTagName { ... }
method domGetChildrenByTagNameNS { ... }
method domNormalize { ... }

enum <SkipBlanks KeepBlanks>;

method unbox { self } # already unboxed

method firstChild { self.first-child(KeepBlanks); }
method firstNonBlankChild { self.first-child(SkipBlanks); }
method lastChild { self.last }

method appendChild(Node $nNode) {
    self.domAppendChild($nNode)
        // self.domError // Node;
}

my subset AttrNode of Node where {!.defined || .type == XML_ATTRIBUTE_NODE};

method setAttribute(QName:D $name, Str:D $value) {
    with self.getAttributeNode($name) {
        .nodeValue = $value;
    }
    else {
        self.SetProp($name, $value);
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

method getAttributeNS(Str $uri, QName:D $att-name --> Str) {
    if $uri { 
        self.NsProp($att-name, $uri);
    }
    else {
        self.Prop($att-name);
    }
}

method localNS {
    .copy with self.ns;
}

method getAttribute(QName:D $att-name) {
    self.domGetAttribute($att-name);
}

method setAttributeNS(Str $uri, QName:D $name, Str:D $value) {
    if $uri {
        self.domSetAttributeNS($uri, $name, $value);
    }
    else {
        self.setAttribute($name, $value);
    }
}

method setNamespace(Str $uri, NCName $prefix) {
    self.domSetNamespace($uri, $prefix);
}

method removeChild(Node:D $child) {
    self.domRemoveChild($child);
}

method replaceChild(Node $child, Node $old) {
    self.domReplaceChild($child, $old)
        // self.domError;
}

method addSibling(Node $new) {
    self.domAddSibling($new)
        // self.domError;
}

method replaceNode(Node $new) {
    self.domReplaceNode($new)
        // self.domError;
}

method !descendants(Str:D $expr = '') {
   self.domXPathSelect("descendant::*" ~ $expr);
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
        // self.domError;
}

method insertAfter(Node:D $nNode, Node $oNode) {
    self.domInsertAfter($nNode, $oNode)
        // self.domError;
}

method cloneNode(Bool:D $deep) {
    my $extended := $deep ?? 1 !! 2;
    with $.doc {
        $.DocCopy($_, $extended);
    }
    else {
        $.Copy( $extended );
    }
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

method parentNode returns Node { self.parent; }

method previousSibling returns Node { self.prev-node(KeepBlanks); }

method previousNonBlankSibling returns Node { self.prev-node(SkipBlanks); }

method appendText(Str:D $text) {
    self.AddContent($text);
}

method appendTextChild(QName:D $name, Str $text) {
    self.domAppendTextChild($name, $text);
}

method lookupNamespacePrefix(Str $uri --> Str) {
    with self.doc.SearchNsByHref(self, $uri) {
        .prefix;
    }
    else {
        Str;
    }
}

method lookupNamespaceURI(Str $prefix --> Str) {
    with self.doc.SearchNs(self, $prefix) {
        .href;
    }
    else {
        Str;
    }
}

method normalize { self.domNormalize }

method getNamespaces {
    my @ns;
    my $ns = self.nsDef;
    while $ns.defined {
        @ns.push: $ns
            if $ns.prefix.defined || $ns.href.defined;
        $ns .= next;
    }
    @ns;
}


sub addr($d) { +nativecast(Pointer, $_) with $d;  }

method isSameNode(Node $oNode) {
    addr(self) ~~ addr($oNode);
}

sub oops($node, Bool $ok is rw, @path, Str:D $msg) {
    my $where = '[' ~ @path.join(',') ~ '] ' ~ $node.domName;
    note $where ~ ' : ' ~ $msg;
    $ok = False;
}

method domCheck(Bool :$recursive = True, :%seen = %(), :@path = [0], Node :$doc = self.doc) {
    # perform various integrity checks on the current node
    # - uniqueness of nodes
    # - parent child links (parent.child === child.parent)
    # - sibling links (prev.next === next.prev)
    # - parent.last == last-sibling
    # - consistant doc entries
    # consider moving to dom.c (profiling/benchmarking needed)

    my Bool $ok = True;
    return oops(self, $ok, @path, "duplicate node")
        if %seen{addr(self)}++;

    oops(self, $ok, @path, "inconsistant owner document")
         unless addr(self.doc) ~~ addr($doc);
    my Node $last;
    my Node $sibling = self.children;
    my @subpath = @path;
    @subpath.push: 0;
    my %siblings-seen;
    while $sibling.defined {
        oops($sibling, $ok, @subpath, "inconsistant parent link")
            unless addr($sibling.parent) ~~ addr(self);
        if %siblings-seen{addr($sibling)}++ {
            oops($sibling, $ok, @subpath, "cycle detected in sibling links");
            last;
        }
        if $recursive {
            $ok = False
                unless $sibling.domCheck(:%seen, :@subpath, :$doc);
        }

        my $next = $sibling.next;

        @subpath.tail++;
        with $next {
            oops($_, $ok, @subpath, "inconsistant prev link")
                unless addr(.prev) == addr($sibling);
        }
        $last = $sibling;
        $sibling = $next;
    }

    oops(self, $ok, @path, "wrong last link")
        unless addr(self.last) ~~ addr($last);

    $ok
}

method baseURI is rw {
    Proxy.new(
        FETCH => sub ($) { self.GetBase },
        STORE => sub ($, Str() $uri) { self.SetBase($uri) }
    );
}

