use v6.c;

use Test;
use LibXML;
use LibXML::Node;

plan 5;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
    <BBB>
        <CCC/>
        <DDD/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <DDD/>
            <CCC/>
            <FFF/>
            <FFF>
                <GGG/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('/AAA/XXX/preceding-sibling::*');

isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'BBB', 'found node is BBB';

$set = $x.find('//CCC/preceding-sibling::*');
is $set.elems , 4, 'found four nodes';

$set = $x.find('/AAA/CCC/preceding-sibling::*[1]');
is $set[0].name , 'XXX', 'found node XXX';

$set = $x.find('/AAA/CCC/preceding-sibling::*[2]');
is $set[0].name , 'BBB', 'found node BBB';

done-testing;
