use v6;
use Test;
plan 10;

use LibXML;
use LibXML::Element;
use LibXML::Document;

# this test fails under XML-LibXML-1.00 with a segfault after the
# second parsing.  it was fixed by putting in code in getChildNodes
# to handle the special case where the node was the document node

  my $input = q:to<EOD>;
    <doc>
       <clean>   </clean>
       <dirty>   A   B   </dirty>
       <mixed>
          A
          <clean>   </clean>
          B
          <dirty>   A   B   </dirty>
          C
       </mixed>
    </doc>
    EOD

for 1 .. 3 -> $time {
    my LibXML $parser .= new();
    my LibXML::Document:D $doc = $parser.parse: :string($input);
    my @a = $doc.getChildnodes;
    is +@a, 1, "1 Child node - time $time";
}

my LibXML $parser .= new();
my $doc = $parser.parse: :string($input);
for 1 .. 3 -> $time {
    lives-ok {my LibXML::Element:D $ = $doc.getFirstChild}, 
    "first child is an Element - time No. $time";
}

for 1 .. 3 -> $time {
    lives-ok {my LibXML::Element:D $ = $doc.getLastChild},
    "last child is an element - time No. $time";
}

{
    my LibXML::Document $doc .= new();

    my LibXML::Element $node = $doc.create(LibXML::Element, 'test');
    $node.setAttribute(contents => "\c[0xE4]");
    $doc.setDocumentElement($node);
    $doc.encoding = 'utf-8';
    is $node.Str(), qq{<test contents="\c[0xE4]"/>}, 'UTF-8 node serialize';
}
