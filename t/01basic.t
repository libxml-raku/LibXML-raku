use v6;
use Test;
use LibXML;
use LibXML::Config;

constant config = LibXML::Config;
constant Min-LibXML-Version = v2.09.00;

plan 9;

my LibXML $p .= new();

ok $p, 'Can initialize a new LibXML instance';

my $version = $p.version;

ok $version, 'LibXML.version is trueish';

diag "Running libxml2 version: " ~ $version;

ok($version >= Min-LibXML-Version, "LibXML version is suppported")
    or diag "sorry this version of libxml is not supported ($version < {Min-LibXML-Version})";

for True, False -> $kb {
    lives-ok { config.keep-blanks-default = $kb }, 'set keep-blanks-default';
    is-deeply config.keep-blanks-default, $kb, 'get keep-blanks-default';
}


my Str $string = '<html><body><h1>Test</h1></body></html>';
my $doc = $p.parse: :$string;

config.skip-xml-declaration = True;

is $doc.Str.chomp, $string, '$doc.Str';
is-deeply $doc.Str(:format).lines, (
    '<html>',
    '  <body>',
    '    <h1>Test</h1>',
    '  </body>',
    '</html>'
), '$doc.Str(:format)';
