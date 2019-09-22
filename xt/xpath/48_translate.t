use v6.c;

use Test;
use LibXML;

plan 4;

my $x = LibXML.parse(string => '<foo/>');
is $x.find('translate("1,234.56", ",", "")'),      1234.56;
is $x.find('translate("bar", "abc", "ABC")'),      "BAr";
is $x.find('translate("--aaa--", "abc-", "ABC")'), "AAA";

# If a character occurs more than once in the second argument string, then the first occurrence determines the replacement character.
is $x.find('translate("--aaa--", "abca-", "ABCX")'), "AAA";

done-testing();
