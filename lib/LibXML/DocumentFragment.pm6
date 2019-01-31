use LibXML::DomNode;

unit class LibXML::DocumentFragment
    is LibXML::DomNode;

use LibXML::Document;
use LibXML::Native;
use NativeCall;

has xmlDocFrag $.node handles <Str>;

submethod TWEAK(xmlDoc :$ref-doc) {
    $!node //= xmlDocFrag.new;
}

method parse-balanced(Str() :$chunk!, xmlSAXHandler :$sax, Pointer :$user-data,  Bool() :$repair) {
    my Pointer[xmlNode] $nodes .= new;
    my $stat = xmlDoc.xmlParseBalancedChunkMemory($sax, $user-data, 0, $chunk, $nodes);
    if $stat && !$repair {
        .deref.FreeList with $nodes;
    }
    else {
        with $nodes {
            .FreeList with $!node.children;
            $!node.set-nodes(.deref);
        }
    }
    $stat;
}

submethod DESTROY {
    with $!node {
        .FreeList with $!node.children;
	$_ = Nil;
    }
}

