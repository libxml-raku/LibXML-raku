use v6;
use LibXML::DomNode;

unit class LibXML::Document
    is LibXML::DomNode;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx is required handles <wellFormed valid>;
has xmlDoc $.node handles<encoding GetRootElement>;

submethod TWEAK {
    $!node //= $!ctx.myDoc;
}

method uri is rw {
    Proxy.new(
        FETCH => sub ($) { $!node.GetBase($!node) },
        STORE => sub ($, Str:D() $_) {
            $!node.SetBase($_);
        }
    )
}

method Str(Bool() :$format = False) {
    my Bool $copied;

    if config.skip-xml-declaration {
        my \skip-dtd = config.skip-dtd;
        $!node.child-nodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str(:$format)).join;
    }
    else {
        my xmlDoc $doc = $!node;
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

sub addr($d) { +nativecast(Pointer, $_) with $d;  }

submethod DESTROY {
    with $!ctx -> $ctx {
        with $!node {
            .Free unless addr($_) ~~ addr($ctx.myDoc);
        }
	$ctx.Free;
    }
    else {
        .Free with $!node;
    }
    $!node = Nil;
    $!ctx = Nil;
}
