unit class LibXML::Writer::Document;

use LibXML::Writer;
also is LibXML::Writer;

use LibXML::Document;
use LibXML::Node;
use LibXML::Raw;
use LibXML::Raw::TextWriter;

has LibXML::Document $.doc is built;
has LibXML::Node     $.node is built;

multi method TWEAK(LibXML::Node:D :$!node!, LibXML::Document :$!doc = $!node.doc) {
    my xmlDoc  $doc  = .raw with $!doc;
    my xmlNode $node = .raw with $!node;
    self.raw = xmlTextWriter.new: :$doc, :$node;
}

multi method TWEAK(LibXML::Document:D :$!doc!) {
    my xmlDoc  $doc  = $!doc.raw;
    my xmlNode $node = .raw with $!node;
    self.raw = xmlTextWriter.new: :$doc, :$node;
}

method Str { .Str with $!doc // $!node }


