use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB><DDD><CCC><DDD/><EEE/></CCC></DDD></BBB>
<CCC><DDD><EEE><DDD><FFF/></DDD></EEE></DDD></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('//DDD/parent::*');
is $set.elems, 4, 'found 1 elements';
is $set[3].name, 'EEE', '3th node is EEE';

done-testing;
