class LibXML::Node {
    use Method::Also;
    use NativeCall;

    use LibXML::Native;
    use LibXML::Native::DOM::Node;
    use LibXML::Config;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::XPathExpression;
    use LibXML::Types :NCName, :QName;

    constant config = LibXML::Config;
    my subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;
    enum <SkipBlanks KeepBlanks>;

    has LibXML::Node $.doc;

    has domNode $.native handles <
        domCheck domFailure
        content
        getAttribute getAttributeNS getNamespaceDeclURI
        hasChildNodes hasAttributes hasAttribute hasAttributeNS
        lookupNamespacePrefix lookupNamespaceURI
        removeAttribute removeAttributeNS
        setNamespaceDeclURI setNamespaceDeclPrefix
        URI baseURI nodeValue
    >;

    BEGIN {
        # wrap methods that return raw nodes
        # simple navigation; no arguments
        for <
             firstChild firstNonBlankChild
             next nextSibling nextNonBlankSibling
             prev previousSibling previousNonBlankSibling
        > {
            $?CLASS.^add_method($_, method { LibXML::Node.box: $!native."$_"() });
        }
        # single node argument constructor
        for <appendChild> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $node) { $node.keep( $!native."$_"($node.native)); });
        }
        for <replaceNode addSibling> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $new) { LibXML::Node.box( $!native."$_"($new.native)); });
        }
        # single node argument unconstructed
        for <isSameNode> {
            $?CLASS.^add_method($_, method (LibXML::Node:D $n1) { $!native."$_"($n1.native) });
        }
        # two node arguments
        for <insertBefore insertAfter> {
            $?CLASS.^add_method(
                $_, method (LibXML::Node:D $node, LibXML::Node $ref) {
                    $node.keep: $!native."$_"($node.native, do with $ref {.native} // domNode);
                });
        }
    }

    method ownerElement is also<parent parentNode> {
        LibXML::Node.box: $!native.parent;
    }
    method last is also<lastChild> {
        LibXML::Node.box: self.native.last;
    }
    method replaceChild(LibXML::Node $new, LibXML::Node $node) {
        $node.keep: $!native.replaceChild($new.native, $node.native),
    }
    method appendText(Str:D $text) {
        $!native.appendText($text);
    }

    method native is rw {
        Proxy.new(
            FETCH => sub ($) { $!native },
            STORE => sub ($, domNode:D $new-struct) {
                given native-class($new-struct.type) -> $class {
                    die "mismatch between DOM node of type {$new-struct.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                        unless $class ~~ self.WHAT|LibXML::Namespace;
                }
                .remove-reference with $!native;
                .add-reference with $new-struct;
                $!native = cast-struct($new-struct);
            },
        );
    }

    submethod TWEAK {
        .add-reference with $!native;
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
                $!doc = native-class(XML_DOCUMENT_NODE).box($struct)
                    if ! ($!doc && !$!doc.native.isSameNode($struct));
            }
            else {
                $!doc = Nil;
            }
            $!doc;
        } // LibXML::Node;
    }

    method doc is rw is also<ownerDocument> {
        Proxy.new(
            FETCH => {
                self.getOwnerDocument;
            },
            STORE => sub ($, LibXML::Node $doc) {
                self.setOwnerDocument($doc);
            },
        );
    }

    method nodeType      { $!native.type }
    method nodeName is also<getName name tagName> {
        $!native.nodeName;
    }
    method localname     { $!native.name }
    method line-number   { $!native.GetLineNo }
    method prefix        { do with $!native.ns {.prefix} // Str }
    method getFirstChild { $.firstChild }
    method getLastChild  { $.lastChild }

    sub native-class(UInt $_) is export(:native-class) {
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

    sub struct-class(UInt $_) {
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

    proto sub native($) is export(:native) {*}
    multi sub native(LibXML::XPathExpression:D $_) { .native }
    multi sub native(LibXML::Node:D $_) { .native }
    multi sub native(LibXML::Namespace:D $_) { .native }
    multi sub native($_) is default  { $_ }

    our sub cast-struct(domNode:D $struct is raw) {
        my $delegate := struct-class($struct.type);
        nativecast( $delegate, $struct);
    }

    sub cast-elem(xmlNodeSetElem:D $elem is raw) is export(:cast-elem) {
        $elem.type == XML_NAMESPACE_DECL
            ?? nativecast(xmlNs, $elem)
            !! cast-struct( nativecast(domNode, $elem) );
    }

    method box(LibXML::Native::DOM::Node $struct,
               LibXML::Node :$doc = $.doc, # reusable document object
              ) {
        do with $struct {
            my $class := native-class(.type);
            die "mismatch between DOM node of type {.type} ({$class.perl}) and container object of class {self.WHAT.perl}"
                    unless $class ~~ self.WHAT|LibXML::Namespace;
            $class.new: :native(cast-struct($_)), :$doc;
        } // self.WHAT; 
    }

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

    proto sub iterate(|) is export(:iterate) {*}
    multi sub iterate($obj, domNode $native, :$doc = $obj.doc, Bool :$keep-blanks = True) {
        # follow a chain of .next links.
        use LibXML::Node::List;
        LibXML::Node::List.new: :type($obj), :$native, :$doc, :$keep-blanks;
    }

    multi sub iterate($range, xmlNodeSet $native, Bool :$values) {
        # iterate through a set of nodes
        (require ::('LibXML::Node::Set')).new( :$native, :$range, :$values )
    }

    my subset AttrNode of LibXML::Node where { !.defined || .nodeType == XML_ATTRIBUTE_NODE };
    multi method addChild(AttrNode:D $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method string-value is also<textContent to-literal> {
        $!native.string-value;
    }
    method unbindNode is also<unlinkNode> {
        $!native.Unlink;
        $!doc = LibXML::Node;
        self;
    }
    method childNodes is also<getChildnodes> {
        iterate(LibXML::Node, $!native.first-child(KeepBlanks));
    }
    method nonBlankChildNodes {
        iterate(LibXML::Node, $!native.first-child(SkipBlanks), :!keep-blanks);
    }
    method getElementsByTagName(Str:D $name) {
        iterate(LibXML::Node, $!native.getElementsByTagName($name));
    }
    method getElementsByLocalName(Str:D $name) {
        iterate(LibXML::Node, $!native.getElementsByLocalName($name));
    }
    method getElementsByTagNameNS(Str $uri, Str $name) {
        iterate(LibXML::Node, $!native.getElementsByTagNameNS($uri, $name));
    }
    method getChildrenByLocalName(Str:D $name) {
        iterate(LibXML::Node, $!native.getChildrenByLocalName($name));
    }
    method getChildrenByTagName(Str:D $name) {
        iterate(LibXML::Node, $!native.getChildrenByTagName($name));
    }
    method getChildrenByTagNameNS(Str:D $uri, Str:D $name) {
        iterate(LibXML::Node, $!native.getChildrenByTagNameNS($uri, $name));
    }
    my subset XPathRange is export(:XPathRange) where LibXML::Node|LibXML::Namespace;
    multi method findnodes(LibXML::XPathExpression:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $!native.findnodes: native($xpath-expr);
        iterate(XPathRange, $node-set);
    }
    multi method findnodes(Str:D $expr) {
        self.findnodes( LibXML::XPathExpression.new: :$expr);
    }
    multi method find(LibXML::XPathExpression:D $xpath-expr, Bool:D $to-bool = False, Bool :$values) {
        given $!native.find( native($xpath-expr), $to-bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_, :$values) }
            default { $_ }
        }
    }
    multi method find(Str:D $expr, |c) {
        self.find( LibXML::XPathExpression.parse($expr), |c);
    }
    multi method findvalue(LibXML::XPathExpression:D $xpath-expr) {
        $.find( $xpath-expr, :values);
    }
    multi method findvalue(Str:D $expr) {
        $.findvalue( LibXML::XPathExpression.parse($expr));
    }
    my subset XPathDomain where LibXML::XPathExpression|Str|Any:U;

    multi method exists(XPathDomain:D $xpath-expr --> Bool:D) {
        $.find($xpath-expr, True);
    }
    multi method setAttribute(NameVal:D $_) {
        $!native.setAttribute(.key, .value);
    }
    multi method setAttribute(QName $name, Str:D $value) {
        $!native.setAttribute($name, $value);
    }
    multi method setAttribute(*%atts) {
        for %atts.pairs.sort -> NameVal $_ {
            $.setAttribute(.key, .value);
        }
    }
    method setAttributeNode(AttrNode:D $att) {
        $att.keep: $!native.setAttributeNode($att.native);
    }
    method setAttributeNodeNS(AttrNode:D $att) {
        $att.keep: $!native.setAttributeNodeNS($att.native);
    }
    multi method setAttributeNS(Str $uri, NameVal:D $_) {
        $!native.setAttributeNS($uri, .key, .value);
    }
    multi method setAttributeNS(Str $uri, QName $name, Str $value) {
        native-class(XML_ATTRIBUTE_NODE).box: $!native.setAttributeNS($uri, $name, $value);
    }
    method getAttributeNode(Str $att-name --> LibXML::Node) {
        native-class(XML_ATTRIBUTE_NODE).box: $!native.getAttributeNode($att-name);
    }
    method getAttributeNodeNS(Str $uri, Str $att-name --> LibXML::Node) {
        native-class(XML_ATTRIBUTE_NODE).box: $!native.getAttributeNodeNS($uri, $att-name);
    }
    method setNamespace(Str $uri, NCName $prefix?, Bool:D() $flag = True) {
        $!native.setNamespace($uri, $prefix, $flag);
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
    method removeAttributeNode(AttrNode $att) {
        $att.keep: $!native.removeAttributeNode($att.native), :doc(LibXML::Node);
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
    method cloneNode(LibXML::Node:D: Bool() $deep = False) {
        LibXML::Node.box: $!native.cloneNode($deep), :doc(LibXML::Node);
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

    method !c14n-str(Bool() :$comments, Bool() :$exclusive, XPathDomain :$xpath is copy, :$selector = self, :@prefix --> Str) {
        my Str $rv;
        my CArray[Str] $prefix .= new: |@prefix, Str;

        if self.defined {
            if $.nodeType != XML_DOCUMENT_NODE|XML_HTML_DOCUMENT_NODE|XML_DOCB_DOCUMENT_NODE {
                ## due to how c14n is implemented, the nodeset it receives must
                ## include child nodes; ie, child nodes aren't assumed to be rendered.
                ## so we use an xpath expression to find all of the child nodes.
                state $AllNodes //= LibXML::XPathExpression.new: expr => '(. | .//node() | .//@* | .//namespace::*)';
                state $NonCommentNodes //= LibXML::XPathExpression.new: expr => '(. | .//node() | .//@* | .//namespace::*)[not(self::comment())]';
                $xpath //= $comments ?? $AllNodes !! $NonCommentNodes;
            }
            my $nodes = $selector.findnodes($_)
                with $xpath;

            $rv := $!native.xml6_node_to_str_C14N(
                +$comments,
                +$exclusive,
                $prefix,
                do with $nodes { .native } else { xmlNodeSet },
            );

            die $_ with $.domFailure;
        }
        $rv;
    }

    method Str(:$C14N, |c) is default {
        if $C14N {
            self!c14n-str(|c);
        }
        else {
            my $options = output-options(|c);
            $!native.Str(:$options);
        }
    }

    method Blob(Str :$enc, |c) {
        my $options = output-options(|c);
        $!native.Blob(:$enc, :$options);
    }

    submethod DESTROY {
        with $!native {
            if .remove-reference {
                # this particular node is no longer referenced directly
                given .root {
                    # release or keep the tree, in it's entirety
                    .Free unless .is-referenced;
                }
            }
        }
    }
}
