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

method domAppendChild  { ... }
method domReplaceChild  { ... }
method domInsertBefore { ... }
method domInsertAfter  { ... }
method domName { ... }
method domGetNodeValue { ... }
method domSetNodeValue { ... }
method domRemoveChild  { ... }
method domGetAttributeNode { ... }
method domGetAttribute { ... }
method domSetAttributeNode { ... }
method domSetAttributeNS { ... }
method domXPathSelect  { ... }
method domGetChildrenByLocalName { ... }
method domGetChildrenByTagName { ... }
method domGetChildrenByTagNameNS { ... }

method firstChild { self.children }
method lastChild { self.last }

method appendChild(Node $nNode) {
    my Node:D $rNode = self.domAppendChild($nNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $rNode;
}

my subset AttrNode of Node where .type == XML_ATTRIBUTE_NODE;

method setAttribute(QName:D $name, Str:D $value) {
    self.SetProp($name, $value);
}

method setAttributeNode(AttrNode $att) {
    self.domSetAttributeNode($att);
}

method getAttributeNode(QName:D $att-name) {
    self.domGetAttributeNode($att-name);
}

method getAttributeNodeNS(Str $uri, QName:D $att-name) {
    self.NsPropNode($att-name, $uri);
}

method getAttributeNS(Str $uri, QName:D $att-name) {
    with $uri { 
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
    self.domSetAttributeNS($uri, $name, $value);
}

method removeChild(Node:D $child) {
    self.domRemoveChild($child);
}

method replaceChild(Node $child, Node $old) {
    self.domReplaceChild($child, $old);
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
    my Node:D $rNode = self.domInsertBefore($nNode, $oNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $nNode;
}

method insertAfter(Node:D $nNode, Node $oNode) {
    my Node:D $rNode = self.domInsertAfter($nNode, $oNode);
    self.doc.intSubset = $nNode
        if $rNode.type == XML_DTD_NODE;
    $nNode;
}

method cloneNode(Bool:D $deep) {
    self.copy: :$deep;
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
    with self.children -> Node:D $node is copy {
        while $node.defined {
            my $next = $node.next;
            $node.Release;
            $node = $next;
        }
    }
}

method hasChildNodes returns Bool {
    ? (self.type != XML_ATTRIBUTE_NODE && self.children.defined)
}

method nextSibling returns Node { self.next; }

method parentNode returns Node { self.parent; }

method nextNonBlankSibling returns Node {
    my $next = self.next;
    $next .= next()
        while $next.defined && $next.isBlankNode;
    $next;
}

method previousSibling returns Node { self.prev; }

method previousNonBlankSibling returns Node {
    my $prev = self.prev;
    $prev .= prev()
        while $prev.defined && $prev.isBlankNode;
    $prev;
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
                unless addr(.prev) ~~ addr($sibling);
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

