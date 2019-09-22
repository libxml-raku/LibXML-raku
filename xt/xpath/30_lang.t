use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<page xml:lang="en">
  <content>Here we go...</content>
  <content xml:lang="de">und hier deutschsprachiger Text :-)</content>
</page>
ENDXML

my $set;
$set = $x.find('//*[ lang("en")]');
is $set.elems, 2, 'found 2 english nodes';

$set = $x.find('//content[ lang("de") ]', :to-list(True));
is $set.elems, 1, 'found 1 german node';

done-testing;
