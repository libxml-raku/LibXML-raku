use v6.c;

use Test;
use LibXML;

plan 7;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
    <BBB/>
    <BBB/>
    <BBB/>
    <BBB/>
    <BBB/>
    <BBB/>
    <BBB/>
    <BBB/>
    <CCC/>
    <CCC/>
    <CCC/>
</AAA>
ENDXML

my $set;
$set = $x.find('//BBB[position()mod2=0]');
is $set.elems, 4, 'found 4 nodes';

$set = $x.find('//BBB[position()=floor(last()div2+0.5)orposition()=ceiling(last()div2+0.5)]');
is $set.elems, 2, 'found 2 nodes';

$set = $x.find('//CCC[position()=floor(last()div2+0.5)orposition()=ceiling(last()div2+0.5)]');
is $set.elems, 1, 'found 1 nodes';

$set = $x.find('//BBB[position()>=3]');
is $set.elems, 6, 'found 6 nodes';

$set = $x.find('//BBB[position()<=3]');
is $set.elems, 3, 'found 3 nodes';

$set = $x.find('//BBB[position()!=1 and position()!=3 and position()!=99]');
is $set.elems, 6, 'found 6 nodes';

$set = $x.find('//BBB[position()*2 mod 3=0]');
is $set.elems, 2, 'found 2 nodes';


done-testing;
