use v6.c;

use Test;
use LibXML;

plan 2;

my $x = LibXML.parse(string => q:to/ENDXML/);
<p>
  <element4>Hello</element4>
  <element5>World</element5>
</p>
ENDXML

is $x.find('concat("1", "2", "3")'), "123", "123";
is $x.find('concat( /p/element4/text(), /p/element5/text() )'), 'HelloWorld', 'HelloWorld';

done-testing;
