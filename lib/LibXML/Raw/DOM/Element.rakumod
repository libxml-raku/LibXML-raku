unit role LibXML::Raw::DOM::Element;

use LibXML::Raw::DOM::Node;
use LibXML::Enums;
use LibXML::Types :NCName, :QName;
use LibXML::Raw::Defs :XML_XMLNS_NS, :XML_XML_NS;

my constant Node = LibXML::Raw::DOM::Node;

method domGetAttributeNode { ... }
method domGetAttributeNodeNS { ... }
method domGetAttribute { ... }
method domGetAttributeNS { ... }
method domSetAttribute { ... }
method domSetAttributeNode { ... }
method domSetAttributeNodeNS { ... }
method domSetAttributeNS { ... }
method domGenNsPrefix { ... }

my subset AttrNode of Node where {!.defined || .type == XML_ATTRIBUTE_NODE};

method setAttribute(QName:D $name, Str:D $value --> UInt) {
    if $name ~~ /^xmlns[\:(.*)|$]/ {
        # user wants to set the special attribute for declaring XML namespace ...

        # this is fine but not exactly DOM conformant behavior, btw (according to DOM we should
        # probably declare an attribute which looks like XML namespace declaration but isn't)
        my NCName $prefix = ($0 // '').Str;
        my QName $nn = self.getNodeName;
        my $uri := $value;

	self.domSetNamespaceDeclURI($prefix, $uri)
        || do {
	    # activate, if the element has the same prefix
            my Bool $activate = ? $nn.starts-with($prefix ~ ':');
            ##
            ## We set the namespace here.
            ## This is helpful, as in:
            ##
            ## |  $e = LibXML::Element.new: :name<foo:bar>;
            ## |  $e.setAttribute('xmlns:foo','http://yoyodine')
            ##
	    self.domSetNamespace($uri, $prefix, +$activate);
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

method hasAttribute(QName:D $att-name --> Bool) {
    self.getAttributeNode($att-name).defined;
}

method hasAttributeNS(Str $uri, QName:D $att-name --> Bool) {
    ? self.domHasAttributeNS($uri, $att-name);
}

method removeAttribute(QName:D $attr-name) {
    with self.getAttributeNode($attr-name) {
        .Release; True;
    }
    else {
        False;
    }
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
    with self.getAttributeNodeNS($uri, $attr-name) {
        .Release; True;
    }
    else {
        False;
    }
}

method getAttributeNodeNS(Str $uri, QName:D $att-name --> AttrNode) {
    self.domGetAttributeNodeNS($uri, $att-name);
}

method getAttributeNS(Str $uri, QName:D $att-name --> Str) {
    self.domGetAttributeNS($uri, $att-name);
}

method getAttribute(QName:D $name) {
    if $name ~~ /^xmlns[\:(.*)|$]/ {
        # user wants to get the special attribute for declaring XML namespace ...

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

        self.domSetAttributeNS($uri, $name, $value) // self.dom-error // Node;
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

method genNsPrefix(NCName $base-prefix?) {
    self.domGenNsPrefix($base-prefix);
}
