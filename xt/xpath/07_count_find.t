use v6.c;

use Test;
use LibXML;

plan 10;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<CCC><BBB/><BBB/><BBB/></CCC>
<DDD><BBB/><BBB/></DDD>
<EEE><CCC/><DDD/></EEE>
<FFF />
</AAA>
ENDXML

my $set;
$set = $x.find('count(/AAA/*)');
is $set, 4, 'found 3 nodes';

$set = $x.find('count(/AAA/*) = 4');
is $set, True, 'found 3 nodes';

$set = $x.find('count(/AAA/*) = 3');
is $set, False, 'found 3 nodes';

$set = $x.find('//*[ count(BBB) = 2 ]', :to-list(True));
is $set.elems, 1 , 'found one node';
is $set[0].name, 'DDD', 'node name is BBB';

$set = $x.find('//*[ count(*) = 2]');
is $set.elems, 2 , 'found two nodes';
is $set[0].name, 'DDD', 'node name is DDD';
is $set[1].name, 'EEE', 'node name is EEE';

$set = $x.find('//*[ count(*) = 3]', :to-list(True));
is $set.elems, 1 , 'found one node';
is $set[0].name, 'CCC', 'node name is CCC';

done-testing;
