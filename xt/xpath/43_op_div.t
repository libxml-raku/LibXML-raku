use v6.c;

use Test;
use LibXML;

plan 7;

my $x = LibXML.parse(string => q:to/ENDXML/);
<p></p>
ENDXML

is $x.find('-4'),       -4,   "-4 == -4";
is $x.find('-4 div 1'), -4,   "-4 div 1 == -4";
is $x.find('4 div 2'),   2,   "4 div 2 == 2";
is $x.find('4 div 0'),   Inf, "4 div 0 == Inf";
is $x.find('-4 div 0'), -Inf, "-4 div 0 == -Inf";
is $x.find('0 div 0'),   NaN, "0 div 0 == NaN";
is $x.find('0 div 2'),   0,   "0 div 2 == 0";

done-testing;
