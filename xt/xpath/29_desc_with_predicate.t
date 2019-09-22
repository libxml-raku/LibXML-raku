use v6.c;

use Test;
use LibXML;
use LibXML::Element;
use LibXML::Text;

plan 4;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB>OK</BBB>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB>NOT OK</BBB></DDD></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('/descendant::BBB[1]');
isa-ok $set[0], LibXML::Element, 'found one node';

is $set[0].nodes.elems, 1, 'one child';
isa-ok $set[0].nodes[0], LibXML::Text, 'child is a text node';
is $set[0].nodes[0].Str, 'OK', 'it is OK';

done-testing;
