use v6.c;

use Test;
use LibXML;

plan 4;

my $x = LibXML.parse(string => q:to/ENDXML/);
<AAA>
  <BBB>
    <DDD>
      <CCC>
        <DDD/>
        <EEE/>
      </CCC>
    </DDD>
  </BBB>
  <CCC>
    <DDD>
      <EEE>
        <DDD>
          <FFF/>
        </DDD>
      </EEE>
    </DDD>
  </CCC>
</AAA>
ENDXML


my $set;
$set = $x.find('/descendant::*');
is $set.elems, 11, 'found 11 elements';

$set = $x.find('/AAA/BBB/descendant::*');
is $set.elems, 4, 'found 4 elements';

$set = $x.find('//CCC/descendant::*');
is $set.elems, 6, 'found 5 elements';

$set = $x.find('//CCC/descendant::DDD');
is $set.elems, 3, 'found 3 elements';

done-testing;
