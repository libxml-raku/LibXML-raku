use v6;
use Test;
use LibXML;
use LibXML::Dtd;

plan 8;

pass("Loaded");

my $dtdstr = 'samples/test.dtd'.IO.slurp;
$dtdstr ~~ s/\n*$//;

ok($dtdstr, "DTD String read");

subtest 'parse a DTD from a SYSTEM ID', {
    my LibXML::Dtd $dtd .= new('ignore', 'samples/test.dtd');
    ok $dtd.defined, 'LibXML::Dtd successful.';
    my @dtd-lines-in =  $dtdstr.lines;
    my @dtd-lines-out = $dtd.Str.lines;
    @dtd-lines-out.shift;
    @dtd-lines-out.pop;
    is-deeply @dtd-lines-out, @dtd-lines-in, 'DTD String same as new string.' ;
}

subtest 'parse a DTD from a string', {

    my LibXML::Dtd $dtd .= parse: :string($dtdstr);
    ok $dtd, '.parse: :$string';
}

subtest 'validate with the DTD', {
    my LibXML::Dtd $dtd .= parse: :string($dtdstr);
    ok($dtd, '.parse_string 2');
    my $xml = LibXML.parse: :file('samples/article.xml');
    ok($xml, 'parse the article.xml file');
    ok($xml.is-valid($dtd), 'valid XML file');
    lives-ok { $xml.validate($dtd) };
}

subtest 'validate a bad document', {
    my LibXML::Dtd $dtd .= parse: :string($dtdstr);
    ok($dtd, '.parse_string 3');
    my $xml = LibXML.parse: :file('samples/article_bad.xml');
    ok(!$xml.is-valid($dtd), 'invalid XML');
    dies-ok {
        $xml.validate($dtd);
    }, '.validate throws an exception';

    my LibXML $parser .= new();
    ok($parser.validation = True, '.validation returns True');
    # this one is OK as it's well formed (no DTD)

    dies-ok {
        $parser.parse: :file('samples/article_bad.xml');
    }, 'Threw an exception';
    dies-ok {
        $parser.parse: :file('samples/article_internal_bad.xml');
    }, 'Throw an exception 2';
}

# this test failed under Perl XML-LibXML-1.00 with a segfault because the
# underlying DTD element in the C libxml library was freed twice

subtest 'childNodes sanity', {
    my LibXML $parser .= new();
    my $doc = $parser.parse: :file('samples/dtd.xml');
    my @a = $doc.childNodes;
    is(+@a, 2, "Two child nodes");
}

subtest 'Perl ticket #2021', {
    quietly { dies-ok { LibXML::Dtd.new("",""); } };
    my LibXML::Dtd $dtd .= new('', 'samples/test.dtd');
    ok(defined($dtd), "LibXML::Dtd.new working correctly");
}
