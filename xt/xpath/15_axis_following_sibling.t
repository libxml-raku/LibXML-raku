use v6.c;

use Test;
use LibXML;

plan 4;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB><CCC/><DDD/></BBB>
<XXX><DDD><EEE/><DDD/><CCC/><FFF/><FFF><GGG/></FFF></DDD></XXX>
<CCC><DDD/></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('/AAA/BBB/following-sibling::*');
is $set.elems, 2, 'found 2 elements';
is $set[1].name, 'CCC', 'node is CCC';


$set = $x.find('//CCC/following-sibling::*');
is $set.elems, 3, 'found 3 elements';
is $set[1].name, 'FFF', 'node is FFF';

done-testing;
