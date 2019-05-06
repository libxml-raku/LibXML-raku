use v6;
use LibXML::Node :output-options;

unit class LibXML::Document
    is LibXML::Node;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Element;
use LibXML::ElementDecl;
use LibXML::Attr;
use LibXML::AttrDecl;
use LibXML::Dtd;
use LibXML::EntityDecl;
use LibXML::EntityRef;
use LibXML::Types :QName, :NCName;
use LibXML::ErrorHandler;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx handles <wellFormed valid>;
has LibXML::Element $!documentElement;

method unbox is rw handles <compression standalone version encoding URI> { callsame() }
method doc { self }

submethod TWEAK(
                Str :$version,
                xmlEncodingStr :$enc,
                Str :$URI,
               ) {
    my xmlDoc:D $struct = self.struct //= do with $!ctx {.myDoc} else {xmlDoc.new};
    .add-reference with $!ctx;
    $struct.version = $_ with $version;
    $struct.encoding = $_ with $enc;
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
    LibXML::Element.box: $.unbox.createElement($name);
}
method createElementNS(Str:D $href, QName:D $name) {
    LibXML::Element.box: $.unbox.createElementNS($href, $name);
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

method importNode(LibXML::Node:D $node) { LibXML::Node.box: $.unbox.importNode($node.unbox); }
method adoptNode(LibXML::Node:D $node)  { LibXML::Node.box: $.unbox.adoptNode($node.unbox); }

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
            $.unbox.documentElement = $!documentElement.unbox;
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
    LibXML::Attr.box: $.unbox.createAttributeNS($href, $name, $value);
}

multi method createAttribute(QName:D $name,
                             Str $value = '',
                            ) {
    LibXML::Attr.box: $.unbox.createAttribute($name, $value);
}

multi method createAttributeNS(Str $href, NameVal $_!, |c) {
    $.createAttributeNS($href, .key, .value, |c);
}
multi method createAttributeNS(Str $href,
                         QName:D $name,
                         Str $value = '',
                        ) {
    LibXML::Attr.box: $.unbox.createAttributeNS($href, $name, $value);
}

method createDocument(Str $URI? is copy, QName $name?, Str $doc-type?, Str :URI($uri), *%opt) {
    $URI //= $uri;
    my $doc = self.new: :$URI, |%opt;
    with $name {
        my LibXML::Node:D $elem = $doc.createElementNS($URI, $_);
        $doc.setDocumentElement($elem);
    }
    $doc.setExternalSubset($_) with $doc-type;
    $doc;
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

method createExternalSubset(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :doc(self), :type<external>, :$name, :$external-id, :$system-id;
}

method createInternalSubset(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :doc(self), :type<internal>, :$name, :$external-id, :$system-id;
}

method createDTD(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :$name, :$external-id, :$system-id, :type<external>;
}

method getInternalSubset {
    LibXML::Dtd.box: self.unbox.getInternalSubset;
}

method setInternalSubset(LibXML::Dtd $dtd) {
    self.unbox.setInternalSubset: $dtd.unbox;
}

method removeInternalSubset {
    LibXML::Dtd.box: self.unbox.removeInternalSubset;
}

method internalSubset is rw {
    Proxy.new( FETCH => sub ($) { self.getInternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setInternalSubset($dtd);
                 }
             );
}

method getExternalSubset {
    LibXML::Dtd.box: self.unbox.getExternalSubset;
}

method setExternalSubset(LibXML::Dtd $dtd) {
    self.unbox.setExternalSubset: $dtd.unbox;
}

method removeExternalSubset {
    LibXML::Dtd.box: self.unbox.removeExternalSubset;
}

method getElementById(Str:D $id --> LibXML::Node) {
    LibXML::Node.box: self.unbox.getElementById($id);
}

method externalSubset is rw {
    Proxy.new( FETCH => sub ($) { self.getExternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setExternalSubset($dtd);
                 }
             );
}

method !validate(LibXML::Dtd:D $dtd-obj = self.getInternalSubset --> Bool) {
    my xmlValidCtxt $cvp .= new;
    my xmlDoc:D $doc = self.unbox;
    my xmlDtd $dtd = .unbox with $dtd-obj;
    # todo: set up error handling
    ? $cvp.validate(:$doc, :$dtd);
}

method validate(|c) { LibXML::ErrorHandler.try: {self!validate(|c)} }
method is-valid(|c) { self!validate(|c) }

our $lock = Lock.new;

method Str(Bool :$skip-dtd = config.skip-dtd, |c --> Str) {
    my Str $rv;

    with self.unbox -> xmlDoc:D $doc {

        my $skipped-dtd = $doc.getInternalSubset
            if $skip-dtd;

        with $skipped-dtd {
            $lock.lock;
            .Unlink;
        }

        $rv := callwith(|c);

        with $skipped-dtd {
            $doc.setInternalSubset($_);
            $lock.unlock;
        }
    }

    $rv;
}

method Blob(Bool() :$skip-decl = config.skip-xml-declaration,
            Bool() :$skip-dtd =  config.skip-dtd,
            xmlEncodingStr:D :$enc is copy = self.encoding // 'UTF-8',
            |c  --> Blob) {

    my Blob $rv;

    if $skip-decl {
        # losing the declaration that encludes the encoding scheme; we need
        # to switch to UTF-8 (default encoding) to stay conformant.
        $enc = 'UTF-8';
    }

    with self.unbox -> xmlDoc:D $doc {

        my $skipped-dtd = $doc.getInternalSubset
            if $skip-dtd;

        with $skipped-dtd {
            $lock.lock;
            .Unlink;
        }

        $rv := callwith(:$enc, :$skip-decl, |c);

        with $skipped-dtd {
            $doc.setInternalSubset($_);
            $lock.unlock;
        }
    }

    $rv;
}

submethod DESTROY {
    with $!ctx {
        .Free if .remove-reference;
    }
    # we're already invoking LibXML::Node.DESTROY to cleanup $.struct
}
