class LibXML::Node {
    use LibXML::Native;
    use LibXML::Native::DOM::Node;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::XPathExpression;
    use LibXML::Types :NCName, :QName;
    use NativeCall;

    my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;
    enum <SkipBlanks KeepBlanks>;

    has LibXML::Node $.doc;

    has domNode $.struct handles <
        domCheck
        Str string-value content
        getAttribute getAttributeNS
        hasChildNodes hasAttributes hasAttribute hasAttributeNS
        lookupNamespacePrefix lookupNamespaceURI
        removeAttribute removeAttributeNS
        URI baseURI nodeName nodeValue
    >;

    BEGIN {
        # wrap methods that return raw nodes
        # simple navigation; no arguments
        for <
             firstChild firstNonBlankChild
             last lastChild
             next nextSibling nextNonBlankSibling
             parent parentNode
             prev previousSibling previousNonBlankSibling
        > {
            $?CLASS.^add_method($_, method { LibXML::Node.box: $.unbox."$_"() });
        }
        # single node argument constructor
        for <appendChild> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $box) { $box.keep( $.unbox."$_"($box.unbox)); });
        }
        for <replaceNode addSibling> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $new) { LibXML::Node.box( $.unbox."$_"($new.unbox)); });
        }
        # single node argument unconstructed
        for <isSameNode> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $.unbox."$_"($n1.unbox) });
        }
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method(
                $_, method (LibXML::Node:D $box, LibXML::Node $ref) {
                    $box.keep($.unbox."$_"($box.unbox, do with $ref {.unbox} else {domNode}));
                });
        }
    }

    method ownerElement { $.parentNode }
    method replaceChild(LibXML::Node $new, $box) {
        $box.keep(
            $.unbox.replaceChild($new.unbox, $box.unbox),
        );
    }
    method appendText(Str:D $text) {
        $.unbox.appendText($text);
    }

    method struct is rw {
        Proxy.new(
            FETCH => sub ($) { $!struct },
            STORE => sub ($, domNode:D $new-struct) {
                given box-class($new-struct.type) -> $class {
                    die "mismatch between DOM node of type {$new-struct.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                        unless $class ~~ self.WHAT|LibXML::Namespace;
                }
                .remove-reference with $!struct;
                .add-reference with $new-struct;
                $!struct = cast-struct($new-struct);
            },
        );
    }

    submethod TWEAK {
        .add-reference with $!struct;
    }

    method doc is rw {
        Proxy.new(
            FETCH => sub ($) {
                with self {
                    with .unbox.doc -> xmlDoc $struct {
                        $!doc = box-class(XML_DOCUMENT_NODE).box($struct)
                            if ! ($!doc && !$!doc.unbox.isSameNode($struct));
                    }
                    else {
                        $!doc = Nil;
                    }
                    $!doc;
                }
                else {
                    LibXML::Node;
                }
            },
            STORE => sub ($, LibXML::Node $doc) {
                with $doc {
                    unless ($!doc && $doc.isSameNode($!doc)) || $doc.isSameNode(self) {
                        $doc.adoptNode(self);
                    }
                }
                $!doc = $doc;
            },
        );
    }

    method nodeType  { $.unbox.type }
    method tagName   { $.nodeName }
    method name      { $.nodeName }
    method localname { $.unbox.name }
    method line-number { $.unbox.GetLineNo }

    sub box-class(UInt $_) {
        when XML_ATTRIBUTE_NODE     { require LibXML::Attr }
        when XML_ATTRIBUTE_DECL     { require LibXML::AttrDecl }
        when XML_CDATA_SECTION_NODE { require LibXML::CDATASection }
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

    sub delegate-struct(UInt $_) {
        when XML_ATTRIBUTE_NODE     { xmlAttr }
        when XML_ATTRIBUTE_DECL     { xmlAttrDecl }
        when XML_CDATA_SECTION_NODE { xmlCDataNode }
        when XML_COMMENT_NODE       { xmlCommentNode }
        when XML_DOCUMENT_FRAG_NODE { xmlDocFrag }
        when XML_DTD_NODE           { xmlDtd }
        when XML_DOCUMENT_NODE
           | XML_HTML_DOCUMENT_NODE { xmlDoc }
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

    our sub cast-struct(domNode:D $struct is raw) {
        my $delegate := delegate-struct($struct.type);
        nativecast( $delegate, $struct);
    }

    sub cast-elem(xmlNodeSetElem:D $elem is raw) {
        $elem.type == XML_NAMESPACE_DECL
            ?? nativecast(xmlNs, $elem)
            !! cast-struct( nativecast(domNode, $elem) );
    }

    method unbox {$!struct}

    method box(LibXML::Native::DOM::Node $struct,
               LibXML::Node :$doc is copy = $.doc, # reusable document object
              ) {
        with $struct {
            my $class := box-class(.type);
            die "mismatch between DOM node of type {.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                    unless $class ~~ self.WHAT|LibXML::Namespace;
            $class.new: :struct(cast-struct($_)), :$doc;
        }
        else {
            self.WHAT
        }
    }

    method keep(LibXML::Native::DOM::Node $struct,
                LibXML::Node :$doc is copy = $.doc, # reusable document object
                --> LibXML::Node) {
        with $struct {
            if self.defined && self.unbox.isSameNode($_) {
                self;
            }
            else {
                # create a new box object. reuse document object, if possible
                die "returned unexpected node: {$.Str}"
                    with self;
                self.box: $_, :$doc;
            }
        }
        else {
            self.WHAT;
        }
    }

    multi sub iterate($obj, domNode $start, :$doc = $obj.doc, Bool :$keep-blanks = True) is export(:iterate) {
        # follow a chain of .next links.
        my class NodeList does Iterable does Iterator {
            has $.cur;
            method iterator { self }
            method pull-one {
                my $this = $!cur;
                $_ = .next-node($keep-blanks) with $!cur;
                with $this {
                    $obj.box: $_, :$doc
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :cur($start) );
    }

    multi sub iterate($range, xmlNodeSet $set) {
        # iterate through a set of nodes
        my class Node does Iterable does Iterator {
            has xmlNodeSet $.set;
            has UInt $!idx = 0;
            submethod DESTROY {
                # xmlNodeSet is managed by us
                .Free with $!set;
            }
            method iterator { self }
            method pull-one {
                if $!set.defined && $!idx < $!set.nodeNr {
                    given $!set.nodeTab[$!idx++].deref {
                        my $class = box-class(.type);
                        die "unexpected node of type {$class.perl} in node-set"
                            unless $class ~~ $range;

                        $class.box: cast-elem($_);
                    }
                }
                else {
                    IterationEnd;
                }
            }
        }.new( :$set );
    }

    method ownerDocument is rw { $.doc }
    method setOwnerDocument(LibXML::Node:D $_) { self.doc = $_ }
    my subset AttrNode of LibXML::Node where { !.defined || .nodeType == XML_ATTRIBUTE_NODE };
    multi method addChild(AttrNode:D $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method textContent { $.string-value }
    method unbindNode {
        $.unbox.Unlink;
        $!doc = LibXML::Node;
        self;
    }
    method childNodes {
        iterate(LibXML::Node, $.unbox.first-child(KeepBlanks));
    }
    method nonBlankChildNodes {
        iterate(LibXML::Node, $.unbox.first-child(SkipBlanks), :!keep-blanks);
    }
    method getElementsByTagName(Str:D $name) {
        iterate(LibXML::Node, $.unbox.getElementsByTagName($name));
    }
    method getElementsByLocalName(Str:D $name) {
        iterate(LibXML::Node, $.unbox.getElementsByLocalName($name));
    }
    method getElementsByTagNameNS(Str $uri, Str $name) {
        iterate(LibXML::Node, $.unbox.getElementsByTagNameNS($uri, $name));
    }
    method getChildrenByLocalName(Str:D $name) {
        iterate(LibXML::Node, $.unbox.getChildrenByLocalName($name));
    }
    method getChildrenByTagName(Str:D $name) {
        iterate(LibXML::Node, $.unbox.getChildrenByTagName($name));
    }
    method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
        iterate(LibXML::Node, $.unbox.getChildrenByTagNameNS($uri, $name));
    }
    my subset XPathRange where LibXML::Node|LibXML::Namespace;
    multi method findnodes(LibXML::XPathExpression:D $xpath-expr) is default {
        iterate(XPathRange, $.unbox.domXPathCompSelect($xpath-expr.unbox));
    }
    multi method findnodes(Str:D $xpath-expr) is default {
        iterate(XPathRange, $.unbox.domXPathSelect($xpath-expr));
    }
    method setAttribute(QName $name, Str:D $value) {
        $.unbox.setAttribute($name, $value);
    }
    method setAttributeNode(AttrNode:D $box) {
        $box.keep: $.unbox.setAttributeNode($box.unbox);
    }
    method setAttributeNodeNS(AttrNode:D $box) {
        $box.keep: $.unbox.setAttributeNodeNS($box.unbox);
    }
    multi method setAttributeNS(Str $uri, NameVal:D $_) {
        $.unbox.setAttributeNS($uri, .key, .value);
    }
    multi method setAttributeNS(Str $uri, QName $name, Str $value) {
        box-class(XML_ATTRIBUTE_NODE).box: $.unbox.setAttributeNS($uri, $name, $value);
    }
    method getAttributeNode(Str $att-name --> LibXML::Node) {
        box-class(XML_ATTRIBUTE_NODE).box: $.unbox.getAttributeNode($att-name);
    }
    method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Node) {
        box-class(XML_ATTRIBUTE_NODE).box: $.unbox.getAttributeNodeNS($uri, $att-name);
    }
    multi method setNamespace(Str $uri, NCName $prefix) {
        $.unbox.setNamespace($uri, $prefix);
    }
    method localNS {
        LibXML::Namespace.box: $.unbox.localNS, :$.doc;
    }

    method getNamespaces {
        $.unbox.getNamespaces.map: { LibXML::Namespace.box($_, :$.doc) }
    }
    method removeChild(LibXML::Node:D $box --> LibXML::Node) {
        $box.keep: $.unbox.removeChild($box.unbox);
    }
    method removeAttributeNode(AttrNode $box) {
        $box.keep: $.unbox.removeAttributeNode($box.unbox);
    }
    method removeChildNodes(--> LibXML::Node) {
        LibXML::Node.box: $.unbox.removeChildNodes;
    }
    multi method appendTextChild(NameVal:D $_) {
        $.unbox.appendTextChild(.key, .value);
    }
    multi method appendTextChild(QName:D $name, Str $value?) {
        $.unbox.appendTextChild($name, $value);
    }
    method normalise { self.unbox.normalize }
    method normalize { self.unbox.normalize }
    method cloneNode(LibXML::Node:D: Bool() $deep) {
        my domNode:D $struct = $.unbox.cloneNode($deep);
        self.new: :$struct, :$.doc;
    }

    multi method write(IO::Handle :$io!, Bool :$format = False) {
        $io.write: self.Blob(:$format);
    }

    multi method write(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :w);
        $.write(:$io, |c);
        $io;
    }

    multi method write(IO() :file($io)!, |c) {
        $.write(:$io, |c).close;
    }

    submethod DESTROY {
        with $!struct {
            if .remove-reference {
                # this node is no longer referenced
                given .root {
                    # release the entire tree, if possible
                    .Free unless .is-referenced;
                }
            }
        }
    }
}
