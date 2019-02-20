use v6;
use LibXML;
use Test;

plan 10;

my LibXML $parser .= new();

my $goodXInclude = q{
<x>
<xinclude:include
 xmlns:xinclude="http://www.w3.org/2001/XInclude"
 href="test2.xml"/>
</x>
};


my $badXInclude = q{
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xinclude:include href="bad.xml"/>
</x>
};

$parser.baseURI = "example/";
$parser.keep-blanks = False;

for 1 .. 10 {
    subtest "xinclude run $_", -> {
        $parser.expand-xinclude = False;
        is-deeply  $parser.expand-xinclude, False, 'expand-xinclude flag';
        my $doc = $parser.parse: :string( $goodXInclude );
        isa-ok($doc, 'LibXML::Document');

        my $i;
        lives-ok { $i = $parser.process-xincludes($doc); }, "process x-includes";
        is( $i, "1", "return value from processXIncludes == 1");
        $doc = $parser.parse: :string( $badXInclude );
        $i = Nil;

        throws-like { $parser.process-xincludes($doc); },
        X::LibXML::Parser,
        :message(rx/'Extra content at the end of the document'/),
        "error parsing a bad include";

        # auto expand
        $parser.expand-xinclude = True;
        $doc = $parser.parse: :string( $goodXInclude );
        isa-ok($doc, 'LibXML::Document'), 'doccy dooo-doos';
    }
}
