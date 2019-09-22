use v6.c;

use Test;
use LibXML;

plan 4;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB/>
<CCC/>
<BBB/>
<DDD><BBB/></DDD>
<CCC><DDD><BBB/><BBB/></DDD></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find("//BBB");
is $set.elems, 5 , 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';

$set = $x.find("//DDD/BBB");
is $set.elems, 3 , 'found three nodes';
is $set[0].name, 'BBB', 'node name is BBB';

done-testing;
