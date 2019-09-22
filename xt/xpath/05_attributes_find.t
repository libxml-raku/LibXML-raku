use v6.c;

use Test;
use LibXML;
use LibXML::Node;

plan 10;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB id='b1'/>
<BBB id='b2'/>
<BBB name='bbb'/>
<BBB />
</AAA>
ENDXML

my $set;
$set = $x.find('//BBB[ @id ]');
is $set.elems, 2 , 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';
is $set[1].name, 'BBB', 'node name is BBB';

$set = $x.find('//BBB[ @name ]');
isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';

$set = $x.find('//BBB[ @* ]');
is $set.elems, 3 , 'found 3 node';
is $set[0].name, 'BBB', 'node name is BBB';

$set = $x.find('//BBB[ not( @* ) ]');
say $set;
isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';
is $set[0].attribs.elems, 0, 'and node really has no attribute';

done-testing;
