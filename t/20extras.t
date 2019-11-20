use v6;
use Test;

plan 12;

use LibXML;

my $string = "<foo><bar/></foo>\n";

my $parser = LibXML.new();

{
    my $doc = $parser.parse: :$string;
    ok($doc, ' TODO : Add test name');
    temp LibXML.skip-xml-declaration = 1;
    is( $doc.Str(), $string, ' TODO : Add test name' );
    temp LibXML.tag-expansion = True;
    is( $doc.Str(), "<foo><bar></bar></foo>\n", ' TODO : Add test name' );
}

{
    temp LibXML.skip-dtd = True;
    temp $parser.expand-entities = False;
    my $doc = $parser.parse: :file( "example/dtd.xml" );
    ok($doc, ' TODO : Add test name');
    my $test = "<doc>This is a valid document &foo; !</doc>\n";
    is( $doc.Str(:skip-decl), $test, 'DTD parse' );
}

{
    my $doc = $parser.parse: :$string;
    ok($doc.defined, 'string parse sanity');
    my $dclone = $doc.cloneNode(:deep);
    ok( ! $dclone.isSameNode($doc), '.isSameNode() on cloned node' );
    ok( $dclone.getDocumentElement(), ' TODO : Add test name' );
    ok( $doc.Str() eq $dclone.Str(), ' TODO : Add test name' );

    my $clone = $doc.cloneNode(:!deep); # shallow
    ok( ! $clone.isSameNode($doc), ' TODO : Add test name' );
    ok( ! $clone.getDocumentElement().defined, ' TODO : Add test name' );
    $doc.getDocumentElement().unbindNode();
    # allow
    is($doc.Str, $clone.Str, "unbind of document element");
}
