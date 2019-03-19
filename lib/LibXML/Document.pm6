use v6;
use LibXML::Node;

unit class LibXML::Document
    is LibXML::Node;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Element;
use LibXML::Attr;
use LibXML::EntityRef;
use LibXML::Types :QName, :NCName;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx handles <wellFormed valid>;
has LibXML::Element $!documentElement;

method struct is rw handles <compression standalone version encoding URI> { callsame() }
method doc { self }

submethod TWEAK(
                Str :$version,
                Str :$encoding,
                Str :$URI,
               ) {
    my xmlDoc:D $struct = self.struct //= do with $!ctx {.myDoc} else {xmlDoc.new};
    $struct.version = $_ with $version;
    $struct.encoding = $_ with $encoding;
    $struct.URI = $_ with $URI;
    with $struct.documentElement {
        $!documentElement .= new: :struct($_), :doc(self);
    }
}

# DOM Methods

multi method createElement(QName $name, Str:D :$href!) {
    $.createElementNS($href, $name);
}
multi method createElement(QName $name) {
    self.dom-node: $.struct.createElement($name);
}
method createElementNS(Str:D $href, QName:D $name) {
    self.dom-node: $.struct.createElementNS($href, $name);
}

method !check-new-node($node, |) {
   if $node ~~ LibXML::Element {
       die "Document already has a root element"
           with $.documentElement;
   }
}

# don't allow more than one element in the document root
method appendChild(LibXML::Node:D $node)    { self!check-new-node($node); nextsame; }
method addChild(LibXML::Node:D $node)       { self!check-new-node($node); nextsame; }
method insertBefore(LibXML::Node:D $node, LibXML::Node $) { self!check-new-node($node); nextsame; }
method insertAfter(LibXML::Node:D $node, LibXML::Node $)  { self!check-new-node($node); nextsame; }

method importNode(LibXML::Node:D $node) { self.dom-node: $.struct.importNode($node.struct); }
method adoptNode(LibXML::Node:D $node)  { self.dom-node: $.struct.adoptNode($node.struct); }

method getDocumentElement { $!documentElement }
method setDocumentElement(LibXML::Element $_) {
    $.documentElement = $_;
}
method documentElement is rw {
    Proxy.new(
        FETCH => sub ($) {
            $!documentElement;
        },
        STORE => sub ($, $!documentElement) {
            $!documentElement.doc = self;
            $.struct.documentElement = $!documentElement.struct;
        }
    );
}

my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;
multi method createAttribute(NameVal $_!, |c) {
    $.createAttribute(.key, .value, |c);
}

multi method createAttribute(QName:D $name,
                             Str $value = '',
                             Str:D :$href!,
                            ) {
    self.dom-node: $.struct.createAttributeNS($href, $name, $value);
}

multi method createAttribute(QName:D $name,
                             Str $value = '',
                            ) {
    self.dom-node: $.struct.createAttribute($name, $value);
}

multi method createAttributeNS(Str $href, NameVal $_!, |c) {
    $.createAttributeNS($href, .key, .value, |c);
}
multi method createAttributeNS(Str $href,
                         QName:D $name,
                         Str $value = '',
                        ) {
    self.dom-node: $.struct.createAttributeNS($href, $name, $value);
}

method createDocument(Str :$version = '1.0',
                      Str :$encoding,
                      Str :$URI,
                      LibXML::Element :$root,
                     ) {
    self.new: :$version, :$encoding, :$URI, :$root;
}

method createDocumentFragment() {
    require LibXML::DocumentFragment;
    LibXML::DocumentFragment.new: :doc(self);
}

method createTextNode(Str $content) {
    require LibXML::Text;
    LibXML::Text.new: :doc(self), :$content;
}

method createComment(Str $content) {
    require LibXML::Comment;
    LibXML::Comment.new: :doc(self), :$content;
}

method createCDATASection(Str $content) {
    require LibXML::CDATASection;
    LibXML::CDATASection.new: :doc(self), :$content;
}

method createEntityReference(Str $name) {
    require LibXML::EntityRef;
    LibXML::EntityRef.new: :doc(self), :$name;
}

method createProcessingInstruction(|c) {
    $.createPI(|c);
}

multi method createPI(NameVal $_!, |c) {
    $.createPI(.key, .value, |c);
}
multi method createPI(NCName $name, Str $content?) {
    need LibXML::PI;
    LibXML::PI.new: :doc(self), :$name, :$content;
}

our $lock = Lock.new;

method Str(Bool() :$format = False) {

    if config.skip-xml-declaration {
        my \skip-dtd = config.skip-dtd;
        $.childNodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str(:$format)).join;
    }
    else {
        my xmlDoc $doc = $.struct;
        my Str $rv;

        if config.skip-dtd && (my $dtd = $doc.internal-dtd).defined {
            $lock.protect: {
                # temporarily remove the DTD
                $dtd.Unlink;

                $rv := $doc.Str(:$format);

                $doc.internal-dtd = $dtd;
            }
        }
        else {
            $rv := $doc.Str(:$format);
        }

        $rv;
    }

}

method Blob(Bool() :$format = False) {
    if config.skip-xml-declaration {
        # losing encoding declaration; switch to UTF-8
        my \skip-dtd = config.skip-dtd;
        $.childNodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str(:$format)).join.encode;
    }
    else {
        my xmlDoc $doc = $.struct;
        my Blob $rv;

        if config.skip-dtd && (my $dtd = $doc.internal-dtd).defined {
            $lock.protect: {
                # temporarily remove the DTD
                $dtd.Unlink;

                $rv := $doc.Blob(:$format);

                $doc.internal-dtd = $dtd;
            }
        }
        else {
            $rv := $doc.Blob(:$format);
        }

        $rv;
    }
}

submethod DESTROY {
    .Free with $!ctx;
    # we're already invoking LibXML::Node.DESTROY
}
