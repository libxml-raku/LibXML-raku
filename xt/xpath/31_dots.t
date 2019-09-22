use v6.c;

use Test;
use LibXML;
use LibXML::Document;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<page></page>
ENDXML

my $set;
my $root = .[0] with $x.find('/.');
isa-ok $root, LibXML::Document, 'found one node';

my $doc = .[0] with $x.find('/..');
nok $doc.defined, 'nothing found';

done-testing;
