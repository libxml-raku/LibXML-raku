use v6;
use LibXML::Node;

unit class LibXML::Document
    is LibXML::Node;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Element;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx is required handles <wellFormed valid>;
# todo eliminate raw node handling
method node(--> xmlDoc) handles<encoding> { callsame }
method root { self }

submethod TWEAK(xmlDoc:D :$node = $!ctx.myDoc) {
    self.set-node: $node;
}

method uri is rw {
    Proxy.new(
        FETCH => sub ($) { $.node.GetBase($.node) },
        STORE => sub ($, Str:D() $_) {
            $.node.SetBase($_);
        }
    )
}

# DOM Methods
method createElement(Str $name) {
    my xmlNode $node .= new: :$name;
    $node.doc = $.node;
    LibXML::Element.new: :$node, :root(self);
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
