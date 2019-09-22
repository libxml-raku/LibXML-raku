use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<xml>
    <a>
        <b>some 1</b>
        <b>value 1</b>
    </a>
    <a>
        <b>some 2</b>
        <b>value 2</b>
    </a>
</xml>
ENDXML

my $set;
$set = $x.find('//a/b[2]');
is $set.elems, 2, 'found 2 nodes';

# value 1
$set = $x.find('(//a/b)[2]');
is $set.elems, 1, 'found 1 nodes';

done-testing;

