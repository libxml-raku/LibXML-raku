use v6;
unit class XML::LibXML::Document;

use XML::LibXML::Native;
use XML::LibXML::Enums;
use XML::LibXML::Config;
use NativeCall;

constant config = XML::LibXML::Config;

has xmlDoc $.struct is required handles<encoding>;

method Str(Bool() $format = False) is default {
    my Pointer[uint8] $p .= new;
    my int32 $len;
    my Bool $copied;

    if config.skip-xml-declaration {
        my \skip-dtd = config.skip-dtd;
        $!struct.child-nodes.grep({ !(skip-dtd && .type == XML_DTD_NODE) }).map(*.Str).join;
    }
    else {
        my xmlDoc $doc = $!struct;
        if $doc.internal-dtd && config.skip-dtd {
            $doc .= copy();
            $doc.xmlUnlinkNode($_) with $doc.internal-dtd;
            $copied = True;
        }

        if $format {
            $doc.xmlDocDumpFormatMemoryEnc($p, $len, 'UTF-8', +$format);
        }
        else {
            $doc.xmlDocDumpMemoryEnc($p, $len, 'UTF-8');
        }

        $doc.free if $copied;
        nativecast(str, $p);
    }
}
