use v6.c;

use Test;
use LibXML;

plan 11;

my $x = LibXML.parse(string => q:to/ENDXML/);
<page></page>
ENDXML

is $x.find('substring("12345", 2, 3)'),             "234";
is $x.find('substring("12345", 2)'),                "2345";
is $x.find('substring("12345", -2)'),                "12345";
is $x.find('substring("12345", 1.5, 2.6)'),          "234";
is $x.find('substring("12345", 0 div 0, 3)'),        "";
is $x.find('substring("12345", 1, 0 div 0)'),        "";
is $x.find('substring("12345", -1 div 0, 1 div 0)'), "";
is $x.find('substring("12345", -42, 1 div 0)'),      "12345";
is $x.find('substring("12345", 0, 1 div 0)'),        "12345";
is $x.find('substring("12345", 0, 3)'),              "12";
is $x.find('substring("12345", -1, 4)'),             "12";

done-testing
