use v6.c;

use Test;
use LibXML;
use LibXML::Node;

plan 8;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
<BBB id="first"/>
<BBB/>
<BBB/>
<BBB id="last"/>
</AAA>
ENDXML

my $set;
$set = $x.find('/AAA/BBB[1]');
isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';
is $set[0].attribs<id>, 'first', 'right node is selected';

$set = $x.find('/AAA/BBB[1]/@id');
isa-ok $set[0], LibXML::Attr, 'found one node';
is $set, 'first', 'node attrib is first';

$set = $x.find('/AAA/BBB[ last() ]');
isa-ok $set[0], LibXML::Node, 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';
is $set[0].attribs<id>, 'last', 'right node is selected';

done-testing;
