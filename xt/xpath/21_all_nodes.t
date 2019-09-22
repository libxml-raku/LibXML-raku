use v6.c;

use Test;
use LibXML;
use LibXML::Node;

plan 15;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
    <BBB>
        <CCC/>
        <ZZZ/>
    </BBB>
    <XXX>
        <DDD>
            <EEE/>
            <FFF>
                <HHH/>
                <GGG> <!-- Watch this node -->
                    <JJJ>
                        <QQQ/>
                    </JJJ>
                    <JJJ/>
                </GGG>
                <VVV/>
            </FFF>
        </DDD>
    </XXX>
    <CCC>
        <DDD/>
    </CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('//GGG/ancestor::*');
is $set.elems, 4, '4 ancestors';

$set = $x.find('//GGG/descendant::*');
is $set.elems, 3, '3 descendants';

$set = $x.find('//GGG/following::*');
is $set.elems, 3, '3 following';
is $set[0].name, 'VVV', '1st following is VVV';
is $set[1].name, 'CCC', '2nd following is CCC';
is $set[2].name, 'DDD', '3rd following is DDD';

$set = $x.find('//GGG/preceding::*');
is $set.elems, 5, '5 preceding';
# document order: BBB not HHH
is $set[0].name, 'BBB', 'first following is BBB';
is $set[1].name, 'CCC', 'first following is CCC';
is $set[2].name, 'ZZZ', 'first following is ZZZ';
is $set[3].name, 'EEE', 'first following is EEE';
is $set[4].name, 'HHH', 'first following is HHH';

$set = $x.find('//GGG/self::*');
isa-ok $set[0] , LibXML::Node, '1 self';
is $set[0].name, 'GGG', 'first following is GGG';

$set = $x.find('//GGG/ancestor::* | //GGG/descendant::* | //GGG/following::* | //GGG/preceding::* | //GGG/self::*');
is $set.elems, 16, '16 nodes summary';

done-testing;

