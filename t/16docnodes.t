use v6;
use Test;
plan 11;

use LibXML;

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
    my $parser = LibXML.new();
    my $doc = $parser.parse: :string($input);
    my @a = $doc.getChildnodes;
    is(+@a, 1, "1 Child node - time $time");
}

my $parser = LibXML.new();
my $doc = $parser.parse: :string($input);
for 1 .. 3 -> $time {
    my $e = $doc.getFirstChild;
    isa-ok($e, 'LibXML::Element',
        "first child is an Element - time No. $time"
    );
}

for 1 .. 3 -> $time {
    my $e = $doc.getLastChild;
    isa-ok($e,'LibXML::Element',
        "last child is an element - time No. $time"
    );
}

{
    my $doc = LibXML::Document.new();

    my $node = LibXML::Element.new('test');
    $node.setAttribute(contents => "\c[0xE4]");
    $doc.setDocumentElement($node);

    is( $node.Str(), '<test contents="&#xE4;"/>', 'Node serialise works.' );
    $doc.encoding = 'utf-8';
    # Second output
    is( $node.Str(),
        qq{<test contents="\c[0xE4]"/>},
        'UTF-8 node serialize',
      );
}
