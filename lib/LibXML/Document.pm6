use v6;
use LibXML::Node;

unit class LibXML::Document
    is LibXML::Node;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Element;
use LibXML::Attr;
use LibXML::Types :QName, :NCName;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx handles <wellFormed valid>;
# todo eliminate raw node handling
method node is rw handles <compression standalone version encoding URI> { callsame() }
method doc { self }

submethod TWEAK(LibXML::Element :$root,
                Str :$version,
                Str :$encoding,
                Str :$URI,
               ) {
    my xmlDoc $node = self.node //= do with $!ctx {.myDoc} else {xmlDoc.new};
    $node.version = $_ with $version;
    $node.encoding = $_ with $encoding;
    $node.URI = $_ with $URI;
    self.documentElement = $_ with $root;
}

# DOM Methods

multi method createElement(QName $name, Str:D :$href!) {
    $.createElementNs($href, $name);
}
multi method createElement(NCName $name) {
    self.dom-node: $.node.createElement($name);
}
method createElementNs(Str:D $href, QName:D $name) {
    self.dom-node: $.node.createElementNs($href, $name);
}

method documentElement is rw {
    Proxy.new(
        FETCH => sub ($) {
            self.dom-node: $.node.documentElement;
        },
        STORE => sub ($, LibXML::Element $elem) {
            $elem.doc = self.doc;
            $.node.documentElement = $elem.node;
        }
    );
}

my subset AttPair of Pair where .key ~~ QName && .value ~~ Str:D;
multi method createAttribute(AttPair $_, |c) {
    $.createAttribute(.key, .value, |c);
}

multi method createAttribute(QName $name,
                             Str $value = '',
                             Str:D :$href!,
                            ) {
    self.dom-node: $.node.createAttributeNS($href, $name, $value);
}

multi method createAttribute(NCName $name,
                             Str $value = '',
                            ) {
    self.dom-node: $.node.createAttribute($name, $value);
}

method createAttributeNS(Str:D $href,
                         QName $name is copy,
                         Str $value = '',
                        ) {
    self.dom-node: $.node.createAttributeNS($href, $name, $value);
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

method Str(Bool() :$format = False) {
    my Bool $copied;

    if config.skip-xml-declaration {
        my \skip-dtd = config.skip-dtd;
        $.childNodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str(:$format)).join;
    }
    else {
        my xmlDoc $doc = $.node;
        with $doc.internal-dtd {
            if config.skip-dtd {
                # make a copy, with DTD removed
                $doc .= copy();
                $doc.xmlUnlinkNode($_);
                .Free;
                $copied = True;
            }
        }

        my $str := $doc.Str(:$format);
        $doc.Free if $copied;
        $str;
    }

}

submethod DESTROY {
    .Free with $!ctx;
    $!ctx = Nil;
    # we've already run LibXML::Node.DESTROY
}
