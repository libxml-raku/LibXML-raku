#| low level un-boxed/unsugared DOM. Works directly on raw XML Nodes
unit role LibXML::Raw::DOM::Node;

use LibXML::Enums;
use LibXML::Types :NCName, :QName;
use NativeCall;

my constant Node = LibXML::Raw::DOM::Node;

method doc { ... }
method type { ... }
method children { ... }
method last { ... }
method copy { ... }
method GetNodePath { ... }
method lock { ... }
method unlock { ... }
method first-child { ... }
method last-child { ... }

method domAppendChild  { ... }
method domAppendTextChild  { ... }
method domReplaceNode  { ... }
method domAddSibling  { ... }
method domReplaceChild  { ... }
method domInsertBefore { ... }
method domInsertAfter  { ... }
method domGetNodeName { ... }
method domSetNodeName { ... }
method domGetXPathKey { ... }
method domGetASTKey { ... }
method domGetNodeValue { ... }
method domSetNodeValue { ... }
method domRemoveChild  { ... }
method domSetNamespaceDeclPrefix { ... }
method domSetNamespaceDeclURI { ... }
method domGetNamespaceDeclURI { ... }
method domSetNamespace { ... }
method domGetChildrenByLocalName { ... }
method domGetChildrenByTagName { ... }
method domGetChildrenByTagNameNS { ... }
method domGetElementsByLocalName { ... }
method domGetElementsByTagName { ... }
method domGetElementsByTagNameNS { ... }
method domAddNewChild { ... }
method domNormalize { ... }
method domUniqueKey { ... }
method domIsSameNode { ... }
method domXPathSelectStr { ...}
enum <SkipBlanks KeepBlanks>;

method native { self } # already native

method firstChild { self.first-child(KeepBlanks); }
method firstNonBlankChild { self.first-child(SkipBlanks); }

method lastChild { self.last-child(KeepBlanks); }
method lastNonBlankChild { self.last-child(SkipBlanks); }

method appendChild($nNode) {
    self.domAppendChild($nNode)
        // self.dom-error // Node;
}

method setNamespaceDeclPrefix(NCName $prefix, NCName $new-prefix --> Int) {
    my $rv := self.domSetNamespaceDeclPrefix($prefix, $new-prefix);
    self.dom-error if $rv < 0;
    $rv;
}

method localNS { self.ns }

method nodePath { self.GetNodePath }

method getNamespaceDeclURI(NCName $prefix) {
    self.domGetNamespaceDeclURI($prefix);
}

method setNamespaceDeclURI(NCName $prefix, Str $uri) {
    self.domSetNamespaceDeclURI($prefix, $uri);
}

sub opt(Str $_) { $_ ?? $_ !! Str }

method setNamespace(Str $uri, NCName $prefix, Bool :$activate) {
    self.domSetNamespace($uri, $prefix, $activate);
}

method removeChild(Node:D $child) {
    self.domRemoveChild($child);
}

method replaceChild(Node $child, Node $old) {
    self.domReplaceChild($child, $old)
        // self.dom-error // Node;
}

method addSibling(Node $new) {
    self.domAddSibling($new)
        // self.dom-error // Node;
}

method replaceNode(Node $new) {
    self.domReplaceNode($new)
        // self.dom-error // Node;
}

method getElementsByTagName(Str:D $name) {
    self.domGetElementsByTagName($name);
}

method getElementsByLocalName(Str:D $name) {
    self.domGetElementsByLocalName($name);
}

method getElementsByTagNameNS(Str() $URI, Str $name) {
    self.domGetElementsByTagNameNS($URI, $name);
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
        // self.dom-error // Node;
}

method insertAfter(Node:D $nNode, Node $oNode) {
    self.domInsertAfter($nNode, $oNode)
        // self.dom-error // Node;
}

method cloneNode(Bool:D $deep) {
    self.copy(:$deep);
}

method getNodeName  { self.domGetNodeName }
method setNodeName(QName $_) { self.domSetNodeName($_) }

method getNodeValue { self.domGetNodeValue }
method setNodeValue(Str $_) { self.domSetNodeValue($_) }

method unique-key { self.domUniqueKey }
method xpath-key { self.domGetXPathKey }
method ast-key { self.domGetASTKey }

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
    self.domAddNewChild($uri, $name);
}

method normalize { self.domNormalize }

multi method isSameNode(Node $oNode) {
    ? self.domIsSameNode($oNode);
}
multi method isSameNode($) is default { False }

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
        if %seen{self.unique-key}++;

    my Node $last;
    my Node $kid = self.children;
    my $is-doc = ? (self.type == XML_DOCUMENT_NODE|XML_HTML_DOCUMENT_NODE|XML_DOCB_DOCUMENT_NODE);
    my @subpath = @path;
    @subpath.push: 0;
    my %kids-seen;
    while $kid.defined {
        oops($kid, $ok, @subpath, "inconsistant parent link (" ~ self.type ~ ')')
            if $kid.parent.unique-key ne self.unique-key
            && $kid.type != XML_ENTITY_DECL;
        if %kids-seen{$kid.unique-key}++ {
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
                unless .prev.uninque.key eq $kid.unique-key;
        }
        $last = $kid;
        $kid = $next;
    }

    oops(self, $ok, @path, "wrong last link {self.last.Str} => {$last.Str}")
        unless self.last.unique-key eq $last.unique-key
        || $last.type == XML_ENTITY_DECL;

    $ok
}

