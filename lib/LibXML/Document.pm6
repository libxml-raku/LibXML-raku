use v6;
use LibXML::Node;

unit class LibXML::Document
    is LibXML::Node;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Element;
use LibXML::Attr;
use LibXML::Types :QName;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx handles <wellFormed valid>;
# todo eliminate raw node handling
method node(--> xmlDoc) handles<compression standalone version encoding URI> { callsame }
method doc { self }

submethod TWEAK(xmlDoc :$node is copy) {
    $node //= .myDoc with $!ctx;
    $node //= xmlDoc.new;
    self.set-node: $node;
}

# DOM Methods

method createElement(QName $name is copy,
                     Str :$prefix is copy,
                     Str :$href,
                    ) {
    with $href {
        without $prefix {
            # try to extract ns prefix from the tag name
            my @s = $name.split(':', 2);
            ($prefix, $name) = @s
                if @s >= 2;
        }
    }

    my xmlNs $ns .= new(:$prefix, :$href)
        if $prefix && $href;
    LibXML::Element.new: :$name, :$ns, :doc(self);
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

method createAttribute(QName $name is copy,
                       Str $value,
                       Str :$prefix is copy,
                       Str :$href,
                    ) {
    with $href {
        without $prefix {
            # try to extract ns prefix from the tag name
            my @s = $name.split(':', 2);
            ($prefix, $name) = @s
                if @s >= 2;
        }
    }

    my xmlNs $ns .= new(:$prefix, :$href)
        if $prefix && $href;
    LibXML::Attr.new: :$name, :$value, :$ns, :doc(self);
}

method createDocument(Str :$version = '1.0',
                      Str :$encoding,
                      Str :$URI,
                      LibXML::Element :$root;
                     ) {
    my xmlDoc $node .= new: :$version;
    $node.encoding = $_ with $encoding;
    $node.URI = $_ with $URI;
    my $doc = self.new: :$node;
    $doc.documentElement = $_ with $root;
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
    with $!ctx -> $ctx {
        with self.node {
            .Free unless .isSameNode($ctx.myDoc);
        }
	$ctx.Free;
    }
    else {
        .Free with self.node;
    }
    self.set-node: _xmlNode;
    $!ctx = Nil;
}
