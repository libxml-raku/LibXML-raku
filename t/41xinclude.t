use v6;
use LibXML;
use LibXML::Enums;
use Test;
plan 13;

my LibXML $parser .= new;
my LibXML::Document $doc;
my $file = 'test/xinclude/test.xml';
{
    $parser.expand-xinclude = False;
    $parser.expand-entities = True;
    $doc = $parser.parse(:$file);
    unlike $doc.Str, /'IT WORKS'/, 'parse: :!expand-xinclude, :expand-entities';
    is-deeply $doc.document-properties, XML_DOC_WELLFORMED +| XML_DOC_NSVALID +| XML_DOC_DTDVALID, 'document properties';
    nok $doc.document-properties(XML_DOC_XINCLUDE), 'xinclude property';
}
{
    $parser.expand-xinclude = True;
    $parser.expand-entities = False;
    $doc = $parser.parse(:$file);
    unlike $doc.Str, /'IT WORKS'/, 'parse: :expand-xinclude, :!expand-entities';
    is-deeply $doc.document-properties(), XML_DOC_WELLFORMED +| XML_DOC_NSVALID +| XML_DOC_DTDVALID +| XML_DOC_XINCLUDE, 'document properties';
    ok $doc.document-properties(XML_DOC_XINCLUDE), 'xinclude property';
}
{
    $parser.expand-xinclude = True;
    $parser.expand-entities = True;
    $doc = $parser.parse(:$file);
    like $doc.Str, /'IT WORKS'/, 'parse: :expand-xinclude, :expand-entities';
}
{
    $parser.expand-xinclude = False;
    $doc = $parser.parse: :$file;
    nok $doc.document-properties(XML_DOC_XINCLUDE), 'xinclude property';
    ok $doc.process-xincludes(:!expand-entities), 'process-xincludes: :!expand-xinclude, :!expand-entities';
    ok $doc.document-properties(XML_DOC_XINCLUDE), 'xinclude property';
    unlike $doc.Str, /'IT WORKS'/, 'process-xincludes: :!expand-xinclude, :!expand-entities';
}
{
    $doc = $parser.parse :$file;
    ok $doc.process-xincludes(:expand-entities), 'process-xincludes: :!expand-xinclude, :expand-entities';
    like $doc.Str, /'IT WORKS'/,  'process-xincludes: :!expand-xinclude, :expand-entities';
}
