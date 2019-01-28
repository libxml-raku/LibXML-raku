unit class LibXML::DocumentFragment;

use LibXML::Document;
use LibXML::Native;
use NativeCall;

has LibXML::Document $.ref-doc;
has xmlDocFrag $.doc handles <Str>;

submethod TWEAK {
    my xmlDoc $ref-doc = .doc with $!ref-doc;
    $!doc //= xmlDocFrag.new: :$ref-doc;
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
            .FreeList with $!doc.children;
            $!doc.set-nodes(.deref);
        }
    }
    $stat;
}

submethod DESTROY {
    with $!doc {
        .Free;
	$_ = Nil;
    }
}

