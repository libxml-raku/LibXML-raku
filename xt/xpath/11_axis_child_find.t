use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB/>
<CCC/>
<DDD><CCC/></DDD>
<EEE/>
</AAA>
ENDXML

my $one-set;
my $other-set;
$one-set   = $x.find('/child::AAA');
$other-set = $x.find('/AAA');

ok($one-set.is-equiv($other-set), 'explicit axis child test');

$one-set   = $x.find('/child::AAA/child::BBB');
$other-set = $x.find('/AAA/BBB');

ok($one-set.is-equiv($other-set), 'explicit axis child test');

done-testing;
