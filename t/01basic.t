use v6;
use Test;
use LibXML;
use LibXML::Config;

constant config = LibXML::Config;

plan 6;

my LibXML $p .= new();

ok $p, 'Can initialize a new LibXML instance';

my $version = $p.parser-version;

ok $version, 'LibXML.parser-version is trueish';

diag "Running libxml2 version: " ~ $version;

for True, False -> $kb {
    lives-ok { config.keep-blanks-default = $kb }, 'set keep-blanks-default';
    is-deeply config.keep-blanks-default, $kb, 'get keep-blanks-default';
}
