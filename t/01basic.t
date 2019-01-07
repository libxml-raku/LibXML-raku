use v6;
use Test;
use XML::LibXML;

plan 6;

my XML::LibXML $p .= new();

ok $p, 'Can initialize a new XML::LibXML instance';

my $version = $p.parser-version;

ok $version, 'XML::LibXML.parser-version is trueish';

diag "Running libxml2 version: " ~ $version;

for True, False -> $kb {
    lives-ok { XML::LibXML.keep-blanks-default = $kb }, 'set keep-blanks-default';
    is-deeply XML::LibXML.keep-blanks-default, $kb, 'get keep-blanks-default';
}
