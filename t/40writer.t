use Test;
plan 3;

use LibXML::Writer;
use LibXML::Document;
use LibXML::Element;

unless LibXML::Writer.have-writer {
    skip-rest "LibXML Writer is not supported in this libxml2 build";
    exit;
}

pass "loaded LibXML::Writer";

subtest 'doc-writer', {
    my LibXML::Document $doc .= new;
    my LibXML::Writer $writer .= new: :$doc;
    $writer.startDocument();
    $writer.startElement('Foo');
    $writer.endElement;
    $writer.endDocument;
    $writer.flush;
    is $writer.doc.root.Str, '<Foo/>';
}


subtest 'node-writer', {
    my LibXML::Document $doc .= new;
    $doc.root = $doc.createElement('Foo');
    my LibXML::Element $node = $doc.root.addChild:  $doc.createElement('Bar');
    my LibXML::Writer $writer .= new: :$node;

    $writer.startDocument();
    $writer.startElement('Baz');
    $writer.endElement;
    $writer.endDocument;
    is $writer.doc.root.Str, '<Foo><Bar><Baz/></Bar></Foo>';
}
