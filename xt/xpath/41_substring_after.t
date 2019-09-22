use v6.c;

use Test;
use LibXML;

plan 4;

my $x = LibXML.parse(string => q:to/ENDXML/);
<foo num="foo" />
ENDXML

is $x.find('substring-after("1999/04/01","/")'), '04/01';
is $x.find('substring-after("1999/04/01","19")'), '99/04/01';
is $x.find('substring-after("1999/04/01","2")'), '';
is $x.find('substring-after(/foo/@num,"x")'), '';

done-testing;
