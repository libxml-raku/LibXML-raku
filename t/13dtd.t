use v6;
use Test;
use LibXML;
use LibXML::Dtd;

plan 18;

pass("Loaded");

my $dtdstr = 'example/test.dtd'.IO.slurp;
$dtdstr ~~ s/\n*$//;

ok($dtdstr, "DTD String read");

{
    # parse a DTD from a SYSTEM ID
    my $dtd = LibXML::Dtd.new('ignore', 'example/test.dtd');
    ok($dtd, 'LibXML::Dtd successful.');
    my @dtd-lines-in =  $dtdstr.lines;
    my @dtd-lines-out = $dtd.Str.lines;
    @dtd-lines-out.shift;
    @dtd-lines-out.pop;
    is-deeply(@dtd-lines-out, @dtd-lines-in, 'DTD String same as new string.');
}

{
    # parse a DTD from a string
    my $dtd = LibXML::Dtd.parse: :string($dtdstr);
    ok($dtd, '.parse_string');
}

{
    # validate with the DTD
    my $dtd = LibXML::Dtd.parse: :string($dtdstr);
    ok($dtd, '.parse_string 2');
    my $xml = LibXML.parse: :file('example/article.xml');
    ok($xml, 'parse the article.xml file');
    ok($xml.is-valid($dtd), 'valid XML file');
    lives-ok { $xml.validate($dtd) };
}

{
    # validate a bad document
    my $dtd = LibXML::Dtd.parse: :string($dtdstr);
    ok($dtd, '.parse_string 3');
    my $xml = LibXML.parse: :file('example/article_bad.xml');
    ok(!$xml.is-valid($dtd), 'invalid XML');
    dies-ok {
        $xml.validate($dtd);
    }, '.validate throws an exception';

    my $parser = LibXML.new();
    ok($parser.validation = True, '.validation returns True');
    # this one is OK as it's well formed (no DTD)

    dies-ok {
        $parser.parse: :file('example/article_bad.xml');
    }, 'Threw an exception';
    dies-ok {
        $parser.parse: :file('example/article_internal_bad.xml');
    }, 'Throw an exception 2';
}

# this test fails under XML-LibXML-1.00 with a segfault because the
# underlying DTD element in the C libxml library was freed twice

{
    my $parser = LibXML.new();
    my $doc = $parser.parse: :file('example/dtd.xml');
    my @a = $doc.childNodes;
    is(+@a, 2, "Two child nodes");
}

##
# Tests for Perl ticket #2021
{
    quietly { dies-ok { LibXML::Dtd.new("",""); } };
}

{
    my $dtd = LibXML::Dtd.new('', 'example/test.dtd');
    ok(defined($dtd), "LibXML::Dtd.new working correctly");
}
