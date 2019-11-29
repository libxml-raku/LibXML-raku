use v6.c;

use Test;
use LibXML;
use LibXML::Element;

plan 3;

my $x = LibXML.parse(string => q:to/ENDXML/);
<foo xmlns:text="http://example.com/text">
<text:footnote text:id="ftn2">
<text:footnote-citation>2</text:footnote-citation>
<text:footnote-body>
<Footnote style="font-size: 10pt; margin-left: 0.499cm;
margin-right: 0cm; text-indent: -0.499cm; font-family: ; ">AxKit
is very flexible in how it lets you transform the XML on the
server, and there are many modules you can plug in to AxKit to
allow you to do these transformations. For this reason, the AxKit
installation does not mandate any particular modules to use,
instead it will simply suggest modules that might help when you
install AxKit.</Footnote>
</text:footnote-body>
</text:footnote>
</foo>
ENDXML

my $set;
my $footnote = $x.first('//Footnote');
isa-ok $footnote, LibXML::Element, 'found a node';


$set = $x.find('ancestor::*', $footnote);
is $set.elems, 3, 'last match has 3 ancestors';

$set = $x.find('ancestor::text:footnote', $footnote);
isa-ok $set[0], LibXML::Element, 'found one text::footnote';

done-testing;

