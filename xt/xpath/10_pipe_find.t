use v6.c;

use Test;
use LibXML;

plan 3;

my $set;
my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB/>
<CCC/>
<DDD><CCC/></DDD>
<EEE/>
</AAA>
ENDXML

$set = $x.find('//CCC | //BBB');
is $set.elems, 3, 'found 3 nodes';

$set = $x.find('/AAA/EEE | //BBB');
is $set.elems, 2, 'found 2 nodes';

$set = $x.find('/AAA/EEE | //DDD/CCC | /AAA | //BBB');
is $set.elems, 4, 'found 4 nodes';

done-testing;
