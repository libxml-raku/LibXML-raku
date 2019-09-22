use v6.c;

use Test;
use LibXML;

plan 3;

my $x = LibXML.parse(string => q:to/ENDXML/);
<foo num="123" />
ENDXML

is $x.find('contains("123","1")'), True, '"123" contains "1"';
is $x.find('contains("123","4")'), False,'"123" does not contain "4"';
is $x.find('contains(/foo/@num,"1")'), True, 'XML Attribute num contains "1"';


done-testing;
