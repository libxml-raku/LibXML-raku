use Test;
plan 5;

use LibXML::Document;
use LibXML::Writer::Buffer;
use LibXML::Writer::Document;
use LibXML::Writer::File;
use LibXML::Element;

unless LibXML::Writer.have-writer {
    skip-rest "LibXML Writer is not supported in this libxml2 build";
    exit;
}

subtest 'buffer writer sanity', {
    my LibXML::Writer::Buffer:D $writer .= new;
    ok $writer.raw.defined;
    $writer.startDocument();
    $writer.startElement('Foo');
    $writer.endElement;
    $writer.endDocument;
    $writer.flush;
    is $writer.Str.lines.join, '<?xml version="1.0"?><Foo/>';
}

subtest 'constructed root', {
    my LibXML::Document $doc .= new;
    my LibXML::Writer::Document:D $writer .= new: :$doc;
    ok $writer.raw.defined;
    $writer.startDocument();
    $writer.startElement('Foo');
    $writer.endElement;
    $writer.endDocument;
    $writer.flush;
    is $writer.doc.root.Str, '<Foo/>';
}

subtest 'nested child contruction', {
    my LibXML::Document $doc .= new;
    $doc.root = $doc.createElement('Foo');
    my LibXML::Element $node = $doc.root.addChild:  $doc.createElement('Bar');
    my LibXML::Writer::Document $writer .= new: :$node;

    $writer.startDocument();
    $writer.startElement('Baz');
    $writer.endElement;
    $writer.endDocument;
    is $writer.doc.root.Str, '<Foo><Bar><Baz/></Bar></Foo>';
}

subtest 'late root attachment', {
    my LibXML::Element $node .= new('Foo');
    my LibXML::Document $doc .= new;
    my LibXML::Writer::Document $writer .= new: :$node, :$doc;

    $writer.startDocument();
    $writer.startElement('Baz');
    $writer.endElement;
    $writer.endDocument;
    is $writer.node.Str, '<Foo><Baz/></Foo>';
    $doc.root = $node;
    is $writer.doc.root.Str, '<Foo><Baz/></Foo>';
}

subtest 'file', {
    use File::Temp;
    my (Str:D $file) = tempfile();
    my LibXML::Writer::File $writer .= new: :$file;

    $writer.startDocument();
    $writer.startElement('Baz');
    $writer.endElement;
    $writer.endDocument;
    $writer.close;
    my $io = $file.IO;
    is $io.lines.join, '<?xml version="1.0"?><Baz/>';
}
