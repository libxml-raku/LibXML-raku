use v6.c;

use Test;
use LibXML;
use LibXML::Document;

plan 7;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
    <BBB/>
    <CCC/>
    <BBB/>
    <CCC/>
    <BBB/>
    <!-- comment -->
    <DDD>
        <BBB/>
        Text
        <BBB/>
    </DDD>
    <CCC/>
</AAA>
ENDXML

my $set;
$set = $x.find("/");
isa-ok $set[0], LibXML::Document, 'found one node';

$set = $x.find("/AAA");
isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'AAA', 'node name is AAA';

$set = $x.find("/AAA/BBB");
is $set.elems, 3 , 'found three nodes';
is $set[0].name, 'BBB', 'node name is BBB';

$set = $x.find("/AAA/DDD/BBB");
is $set.elems, 2 , 'found 2 nodes';
is $set[0].name, 'BBB', 'node name is BBB';

done-testing;
