use v6;
use Test;

plan 13;

use LibXML;
use LibXML::Attr;
use LibXML::Document;

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
    is( $doc.Str(:skip-xml-declaration), $test, 'DTD parse' );
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

subtest 'attribute child nodes' => {
    plan 3;
    my LibXML::Document $doc .= parse: :file<example/dtd.xml>;
    my $elem = $doc.createElement: "Test";
    my LibXML::Attr $att .= new: :name<att>, :value('xxx');
    $att.addChild: $doc.createEntityReference('foo');
    is $att.Str, "xxx test ";
    isa-ok $att.childNodes[1], 'LibXML::EntityRef';
    $elem.setAttributeNode($att);
    is $elem.Str, '<Test att="xxx&foo;"/>';
}
