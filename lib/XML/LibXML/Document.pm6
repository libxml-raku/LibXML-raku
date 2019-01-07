use v6;
unit class XML::LibXML::Document;

use XML::LibXML::Native;
use XML::LibXML::Enums;
use NativeCall;

has xmlDoc $.struct is required handles<encoding>;

our $skipXMLDeclaration;
our $skipDTD;

method Str(Bool() $format = False) is default {
    my Pointer[uint8] $p .= new;
    my int32 $len;

    if $skipXMLDeclaration {
        $!struct.child-nodes.grep({ !($skipDTD && .nodeType == XML_DTD_NODE) }).map(*.Str).join;
    }
    else {
        my xmlDoc $doc = $!struct;
    if $doc.dtd && $skipDTD {
            given $doc.copy() {
                $doc.free;
                $doc = $_;
                $doc.xmlUnlinkNode($_) with $doc.dtd;
            }
        }

        if $format {
            $doc.xmlDocDumpFormatMemoryEnc($p, $len, 'UTF-8', +$format);
        }
        else {
            $doc.xmlDocDumpMemoryEnc($p, $len, 'UTF-8');
        }

        nativecast(str, $p);
    }
}
