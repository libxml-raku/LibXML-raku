use Test;
plan 7;

use LibXML::Document;
use LibXML::Writer::Buffer;
use LibXML::Writer::Document;
use LibXML::Writer::File;
use LibXML::Writer::PushParser;
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

subtest 'push-parser', {
    use  LibXML::SAX::Handler::SAX2;
    class SAXShouter is LibXML::SAX::Handler::SAX2 {
        use LibXML::SAX::Builder :sax-cb;
        method startElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method endElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method characters($chars, |c) is sax-cb {
            nextwith($chars.uc, |c);
        }
    }

    my SAXShouter $sax-handler .= new;
    my LibXML::Writer::PushParser $writer .= new: :$sax-handler;

    $writer.startDocument();
    $writer.startElement('Foo');
    $writer.startElement('Bar');
    $writer.endElement;
    $writer.flush;
    $writer.push('<Baz/>');
    $writer.endElement;
    $writer.endDocument;
    my $doc = $writer.finish-push;
    is $doc.Str.lines.join, '<?xml version="1.0" encoding="UTF-8"?><FOO><BAR/><BAZ/></FOO>';
}

sub tail($writer, &m) {
    $writer.writeText: "\n";
    &m($writer);
    $writer.flush;
    $writer.Str.lines.tail;
}

subtest 'writing methods', {
    my LibXML::Writer::Buffer:D $writer .= new;
    ok $writer.raw.defined;
    $writer.startDocument();
    $writer.startElement('Test');

    is tail($writer, { .writeElement('Xxx') }), '<Xxx/>';
    is tail($writer, { .writeElement('Xxx', 'Yy>yy') }), '<Xxx>Yy&gt;yy</Xxx>';

    is tail($writer, { .writeElementNS('Foo') }), '<Foo></Foo>';
    is tail($writer, { .writeElementNS('Foo', 'x&y') }), '<Foo>x&amp;y</Foo>';
    is tail($writer, { .writeElementNS('Foo', :prefix<p>) }), '<p:Foo></p:Foo>';
    is tail($writer, { .writeElementNS('Foo', :uri<https::/example.org>) }), '<Foo xmlns="https::/example.org"></Foo>';
    is tail($writer, { .writeElementNS('Foo', :prefix<p> :uri<https::/example.org>) }), '<p:Foo xmlns:p="https::/example.org"></p:Foo>';

    is tail($writer, { .startElement('Foo'); .writeAttribute("k", "a&b"); .endElement() }), '<Foo k="a&amp;b"/>';
    is tail($writer, { .startElementNS('Foo', :prefix<p>); .writeAttributeNS("k", "a&b", :prefix<q>); .endElement() }), '<p:Foo q:k="a&amp;b"/>';

    is tail($writer, { .writeComment('Yy-->yy') }), '<!--Yy--><!--yy-->';

    is tail($writer, { .writeText('A&B') }), 'A&amp;B';
    is tail($writer, { .writeRaw('A&amp;B') }), 'A&amp;B';
    is tail($writer, { .writeCDATA('A&B') }), '<![CDATA[A&B]]>';
    is tail($writer, { .writeCDATA('A&B]]>') }), '<![CDATA[A&B]]]><![CDATA[]>]]>';

    $writer.endElement;
    $writer.endDocument;

}
