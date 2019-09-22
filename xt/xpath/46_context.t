use v6.c;

use Test;
use LibXML;

plan 1;

my $x = LibXML.parse(string => q:to/ENDXML/);
<text>
  <para>
    I start the text here, I break
    the line and I go on, I <blink>twinkle</blink> and then I go on
    again.
    This is not a new paragraph.
  </para>
  <para>
    This is a
    <important>new</important> paragraph and
    <blink>this word</blink> has a preceding sibling.
  </para>
</text>
ENDXML

my $set1 = $x.find("text/para/node()[position()=last() and preceding-sibling::important]");
my $set2 = $x.find("text/para/node()[preceding-sibling::important and position()=last()]");

ok $set1.is-equiv($set2),'both expressions are the same';

done-testing();
