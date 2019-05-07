class LibXML::Node {
    use LibXML::Native;
    use LibXML::Native::DOM::Node;
    use LibXML::Config;
    use LibXML::Enums;
    use LibXML::Namespace;
    use LibXML::XPathExpression;
    use LibXML::Types :NCName, :QName;
    use NativeCall;

    constant config = LibXML::Config;
    my subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;
    enum <SkipBlanks KeepBlanks>;

    has LibXML::Node $.doc;

    has domNode $.struct handles <
        domCheck domFailure
        string-value content
        getAttribute getAttributeNS getNamespaceDeclURI
        hasChildNodes hasAttributes hasAttribute hasAttributeNS
        lookupNamespacePrefix lookupNamespaceURI
        removeAttribute removeAttributeNS
        setNamespaceDeclURI setNamespaceDeclPrefix
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
            $?CLASS.^add_method($_, method (LibXML::Node:D $node) { $node.keep( $.unbox."$_"($node.unbox)); });
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
                $_, method (LibXML::Node:D $node, LibXML::Node $ref) {
                    $node.keep: $.unbox."$_"($node.unbox, do with $ref {.unbox} else {domNode});
                });
        }
    }

    method ownerElement { $.parentNode }
    method replaceChild(LibXML::Node $new, LibXML::Node $node) {
        $node.keep: $.unbox.replaceChild($new.unbox, $node.unbox),
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

    method nodeType      { $.unbox.type }
    method tagName       { $.nodeName }
    method name          { $.nodeName }
    method getName       { $.nodeName }
    method localname     { $.unbox.name }
    method line-number   { $.unbox.GetLineNo }
    method prefix        { with $.unbox.ns {.prefix} else { Str } }
    method getFirstChild { $.firstChild }
    method getLastChild  { $.lastChild }

    sub box-class(UInt $_) is export(:box-class) {
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

    proto sub unbox($) is export(:unbox) {*}
    multi sub unbox(LibXML::XPathExpression:D $_) { .unbox }
    multi sub unbox(LibXML::Node:D $_) { .unbox }
    multi sub unbox(LibXML::Namespace:D $_) { .unbox }
    multi sub unbox($_) is default  { $_ }

    our sub cast-struct(domNode:D $struct is raw) {
        my $delegate := struct-class($struct.type);
        nativecast( $delegate, $struct);
    }

    sub cast-elem(xmlNodeSetElem:D $elem is raw) is export(:cast-elem) {
        $elem.type == XML_NAMESPACE_DECL
            ?? nativecast(xmlNs, $elem)
            !! cast-struct( nativecast(domNode, $elem) );
    }

    method unbox {$!struct}

    method box(LibXML::Native::DOM::Node $struct,
               LibXML::Node :$doc = $.doc, # reusable document object
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

    method keep(LibXML::Native::DOM::Node $raw,
                LibXML::Node :$doc = $.doc, # reusable document object
                --> LibXML::Node) {
        with $raw {
            if self.defined && unbox(self).isSameNode($_) {
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

    proto sub iterate(|) is export(:iterate) {*}
    multi sub iterate($obj, domNode $list, :$doc = $obj.doc, Bool :$keep-blanks = True) {
        # follow a chain of .next links.
        use LibXML::Node::List;
        LibXML::Node::List.new: :type($obj), :$list, :$doc, :$keep-blanks;
    }

    multi sub iterate($range, xmlNodeSet $set, Bool :$values) {
        # iterate through a set of nodes
        (require ::('LibXML::Node::Set')).new( :$set, :$range, :$values )
    }

    method ownerDocument is rw { $.doc }
    method setOwnerDocument(LibXML::Node:D $_) { self.doc = $_ }
    my subset AttrNode of LibXML::Node where { !.defined || .nodeType == XML_ATTRIBUTE_NODE };
    multi method addChild(AttrNode:D $a) { $.setAttributeNode($a) };
    multi method addChild(LibXML::Node $c) is default { $.appendChild($c) };
    method textContent { $.string-value }
    method to-literal { $.string-value }
    method unbindNode {
        $.unbox.Unlink;
        $!doc = LibXML::Node;
        self;
    }
    method childNodes {
        iterate(LibXML::Node, $.unbox.first-child(KeepBlanks));
    }
    method getChildnodes { $.childNodes }
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
    my subset XPathRange is export(:XPathRange) where LibXML::Node|LibXML::Namespace;
    multi method findnodes(LibXML::XPathExpression:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $.unbox.findnodes: unbox($xpath-expr);
        iterate(XPathRange, $node-set);
    }
    multi method findnodes(Str:D $expr) {
        self.findnodes( LibXML::XPathExpression.new: :$expr);
    }
    multi method find(LibXML::XPathExpression:D $xpath-expr, Bool:D $to-bool = False, Bool :$values) {
        given $.unbox.find( unbox($xpath-expr), $to-bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_, :$values) }
            default { $_ }
        }
    }
    multi method find(Str:D $expr, |c) {
        self.find( LibXML::XPathExpression.new(:$expr), |c);
    }
    multi method findvalue(LibXML::XPathExpression:D $xpath-expr) {
        $.find( $xpath-expr, :values);
    }
    multi method findvalue(Str:D $expr) {
        $.findvalue( LibXML::XPathExpression.new(:$expr));
    }
    my subset XPathDomain where LibXML::XPathExpression|Str|Any:U;

    multi method exists(XPathDomain:D $xpath-expr --> Bool:D) {
        $.find($xpath-expr, True);
    }
    multi method setAttribute(NameVal:D $_) {
        $.unbox.setAttribute(.key, .value);
    }
    multi method setAttribute(QName $name, Str:D $value) {
        $.unbox.setAttribute($name, $value);
    }
    multi method setAttribute(*%atts) {
        for %atts.pairs.sort -> NameVal $_ {
            $.setAttribute(.key, .value);
        }
    }
    method setAttributeNode(AttrNode:D $att) {
        $att.keep: $.unbox.setAttributeNode($att.unbox);
    }
    method setAttributeNodeNS(AttrNode:D $att) {
        $att.keep: $.unbox.setAttributeNodeNS($att.unbox);
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
    method setNamespace(Str $uri, NCName $prefix?, Bool:D() $flag = True) {
        $.unbox.setNamespace($uri, $prefix, $flag);
    }
    method localNS {
        LibXML::Namespace.box: $.unbox.localNS;
    }
    method getNamespaces {
        $.unbox.getNamespaces.map: { LibXML::Namespace.box($_) }
    }
    method namespaces { $.getNamespaces }
    method namespaceURI(--> Str) { with $.unbox.ns {.href} else {Str} }
    method getNamespaceURI { $.namespaceURI }
    method removeChild(LibXML::Node:D $node --> LibXML::Node) {
        $node.keep: $.unbox.removeChild($node.unbox), :doc(LibXML::Node);
    }
    method removeAttributeNode(AttrNode $att) {
        $att.keep: $.unbox.removeAttributeNode($att.unbox), :doc(LibXML::Node);
    }
    method removeChildNodes(--> LibXML::Node) {
        LibXML::Node.box: $.unbox.removeChildNodes, :doc(LibXML::Node);
    }
    multi method appendTextChild(NameVal:D $_) {
        $.unbox.appendTextChild(.key, .value);
    }
    multi method appendTextChild(QName:D $name, Str $value?) {
        $.unbox.appendTextChild($name, $value);
    }
    method addNewChild(Str $uri, QName $name) {
        LibXML::Node.box: $.unbox.domAddNewChild($uri, $name);
    }
    method normalise { self.unbox.normalize }
    method normalize { self.unbox.normalize }
    method cloneNode(LibXML::Node:D: Bool() $deep = False) {
        LibXML::Node.box: $.unbox.cloneNode($deep), :doc(LibXML::Node);
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
                constant AllNodes = '(. | .//node() | .//@* | .//namespace::*)';
                constant NonCommentNodes = '(. | .//node() | .//@* | .//namespace::*)[not(self::comment())]';
                $xpath //= $comments ?? AllNodes !! NonCommentNodes;
            }
            my $nodes = $selector.findnodes($_)
                with $xpath;

            $rv := $.unbox.xml6_node_to_str_C14N(
                +$comments,
                +$exclusive,
                $prefix,
                do with $nodes { .unbox } else { xmlNodeSet },
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
            $.unbox.Str(:$options);
        }
    }

    method Blob(Str :$enc, |c) {
        my $options = output-options(|c);
        $.unbox.Blob(:$enc, :$options);
    }

    submethod DESTROY {
        with $!struct {
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
