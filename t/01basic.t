use v6;
use Test;
use XML::LibXML;
use XML::LibXML::Config;

constant config = XML::LibXML::Config;

plan 6;

my XML::LibXML $p .= new();

ok $p, 'Can initialize a new XML::LibXML instance';

my $version = $p.parser-version;

ok $version, 'XML::LibXML.parser-version is trueish';

diag "Running libxml2 version: " ~ $version;

for True, False -> $kb {
    lives-ok { config.keep-blanks-default = $kb }, 'set keep-blanks-default';
    is-deeply config.keep-blanks-default, $kb, 'get keep-blanks-default';
}
