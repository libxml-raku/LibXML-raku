use v6.c;

use Test;
use LibXML;
use LibXML::Document;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<page></page>
ENDXML

my $set;
my $root = $x.first('/.');
isa-ok $root, LibXML::Document, 'found one node';

my $doc = $x.first('/..');
nok $doc.defined, 'nothing found';

done-testing;
