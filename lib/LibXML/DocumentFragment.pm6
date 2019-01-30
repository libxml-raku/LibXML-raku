use LibXML::DomNode;

unit class LibXML::DocumentFragment
    is LibXML::DomNode;

use LibXML::Document;
use LibXML::Native;
use NativeCall;

has LibXML::Document $.ref-doc;
has xmlDocFrag $.node handles <Str>;

submethod TWEAK {
    my xmlDoc $ref-doc = .doc with $!ref-doc;
    $!node //= xmlDocFrag.new: :$ref-doc;
}

method parse-balanced(Str() :$chunk!, xmlSAXHandler :$sax, Pointer :$user-data,  Bool() :$repair) {
    my xmlDoc $ref-doc = .doc with $!ref-doc;
    $_ .= new without $ref-doc;
    my Pointer[xmlNode] $nodes .= new;
    my $stat = $ref-doc.xmlParseBalancedChunkMemory($sax, $user-data, 0, $chunk, $nodes);
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
        .Free;
	$_ = Nil;
    }
}

