use v6;
use Test;
use LibXML;
use LibXML::Config;
use LibXML::Document;

constant config = LibXML::Config;
constant Min-LibXML-Version = v2.08.00;

plan 8;

my LibXML:D $p .= new();

my $version = $p.version;

ok $version, 'LibXML.version is trueish';
sub yn($_) { .so ?? 'yes' !! 'no' }
diag "Running libxml2 version: $version (module {LibXML.^ver}, Raku {$*RAKU.compiler.version})";
diag "Configuration: threads={yn config.have-threads} reader={yn config.have-reader} schemas={yn config.have-schemas} compression={yn config.have-compression} writer={yn config.have-writer}"; #
given LibXML.config-version {
    diag "***NOTE was configured against libxml2 version $_ ***"
        unless $_ == $version
}

ok $version >= Min-LibXML-Version, "LibXML version is suppported"
    or diag "sorry this version of libxml is not supported ($version < {Min-LibXML-Version})";

for True, False -> $kb {
    lives-ok { config.keep-blanks = $kb }, 'set keep-blanks default';
    is-deeply config.keep-blanks, $kb, 'get keep-blanks default';
}

my Str $string = '<html><body><h1>Test</h1></body></html>';
my LibXML::Document:D $doc = $p.parse: :$string;

$doc.config.skip-xml-declaration = True;

is $doc.Str.chomp, $string, '$doc.Str';
is-deeply $doc.Str(:format).lines, (
    '<html>',
    '  <body>',
    '    <h1>Test</h1>',
    '  </body>',
    '</html>'
), '$doc.Str(:format)';
