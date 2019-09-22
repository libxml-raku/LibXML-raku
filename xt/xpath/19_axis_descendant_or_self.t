use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB><CCC/><ZZZ><DDD/></ZZZ></BBB>
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
<CCC><DDD/></CCC>
</AAA>
ENDXML

my $set;
$set = $x.find('/AAA/XXX/descendant-or-self::*');
is $set.elems, 8, 'found 8 nodes';

$set = $x.find('//CCC/descendant-or-self::*');
is $set.elems, 4, 'found 4 nodes';

done-testing;
