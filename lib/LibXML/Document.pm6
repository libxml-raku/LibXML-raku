use v6;
unit class LibXML::Document;

use LibXML::Native;
use LibXML::Enums;
use LibXML::Config;
use NativeCall;

constant config = LibXML::Config;
has parserCtxt $.ctx is rw is required handles <wellFormed valid>;
has xmlDoc $.doc handles<encoding GetRootElement>;

submethod TWEAK {
    $!doc //= $!ctx.myDoc;
}

method uri is rw {
    Proxy.new(
        FETCH => sub ($) { $!doc.GetBase($!doc) },
        STORE => sub ($, Str:D() $_) {
            $!doc.SetBase($_);
        }
    )
}

method Str(Bool() :$format = False) is default {
    my Bool $copied;

    if config.skip-xml-declaration {
        my \skip-dtd = config.skip-dtd;
        $!doc.child-nodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str(:$format)).join;
    }
    else {
        my xmlDoc $doc = $!doc;
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
        $!doc.Free
	    unless addr($!doc) ~~ addr($!ctx.myDoc);
	$ctx.Free;
    }
    $!doc = Nil;
    $!ctx = Nil;
}
