use v6.c;

use Test;
use LibXML;

plan 11;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB><DDD><CCC><DDD/><EEE/></CCC></DDD></BBB>
<CCC><DDD><EEE><DDD><FFF/></DDD></EEE></DDD></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('/AAA/BBB/DDD/CCC/EEE/ancestor::*');
is $set.elems, 4, 'found 4 elements';
is $set[3].name, 'CCC', 'node is CCC';
is $set[2].name, 'DDD', 'node is EEE';
is $set[1].name, 'BBB', 'node is BBB';
is $set[0].name, 'AAA', 'node is AAA';

$set = $x.find('//FFF/ancestor::*');
is $set.elems, 5, 'found 5 elements';
is $set[4].name, 'DDD', 'node is DDD';
is $set[3].name, 'EEE', 'node is EEE';
is $set[2].name, 'DDD', 'node is DDD';
is $set[1].name, 'CCC', 'node is CCC';
is $set[0].name, 'AAA', 'node is AAA';

done-testing;
