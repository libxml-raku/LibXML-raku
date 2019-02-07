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
method root { self }

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
    LibXML::Element.new: :$name, :$ns, :root(self);
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
    LibXML::Attr.new: :$name, :$value, :$ns, :root(self);
}

method createDocument(Str :$version = '1.0',
                      Str :$encoding,
                      Str :$URI) {
    my xmlDoc $node .= new: :$version;
    $node.encoding = $_ with $encoding;
    $node.URI = $_ with $URI;
    my $doc = self.new: :$node;
    
}

method createDocumentFragment() {
    require LibXML::DocumentFragment;
    LibXML::DocumentFragment.new: :root(self);
}

method createTextNode(Str $content) {
    require LibXML::Text;
    LibXML::Text.new: :root(self), :$content;
}

method createComment(Str $content) {
    require LibXML::Comment;
    LibXML::Comment.new: :root(self), :$content;
}

method createCDATASection(Str $content) {
    require LibXML::CDATASection;
    LibXML::CDATASection.new: :root(self), :$content;
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
