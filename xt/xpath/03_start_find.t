use v6.c;

use Test;
use LibXML;

plan 6;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
  <XXX>
    <DDD>
      <BBB/>
      <BBB/>
      <EEE/>
      <FFF/>
    </DDD>
  </XXX>
  <CCC>
    <DDD>
      <BBB/>
      <BBB/>
      <EEE/>
      <FFF/>
    </DDD>
  </CCC>
  <CCC>
    <BBB>
      <BBB>
        <BBB/>
      </BBB>
    </BBB>
  </CCC>
</AAA>
ENDXML

my $set;
$set = $x.find("/AAA/CCC/DDD/*");
is $set.elems, 4 , 'found one node';
is $set[0].name, 'BBB', 'node name is BBB';

$set = $x.find("/*/*/*/BBB");
is $set.elems, 5 , 'found 5 nodes';
is $set[0].name, 'BBB', 'node name is BBB';
for $set.values -> $node {
    say $node;
}

$set = $x.find("//*");
is $set.elems, 17 , 'found 17 nodes';
is $set[0].name, 'AAA', 'node name is BBB';

done-testing;
