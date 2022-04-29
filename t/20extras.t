use v6;
use Test;

plan 4;

use LibXML;
use LibXML::Attr;
use LibXML::Document;

my $string = "<foo><bar/></foo>\n";

my LibXML $parser .= new();

subtest ':skip-xml-declaration, :tag-expansion', {
    my LibXML::Document:D $doc = $parser.parse: :$string;
    temp LibXML.skip-xml-declaration = 1;
    is $doc.Str(), $string, ':skip-xml-declaration';
    temp LibXML.tag-expansion = True;
    is $doc.Str(), "<foo><bar></bar></foo>\n", ':tag-expansion';
}

subtest ':exand-entities', {
    temp LibXML.skip-dtd = True;
    temp $parser.expand-entities = False;
    my LibXML::Document:D $doc = $parser.parse: :file( "samples/dtd.xml" );
    my $test = "<doc>This is a valid document &foo; !</doc>\n";
    is $doc.Str(:skip-xml-declaration), $test, ':!expand-entities';
}

subtest 'cloneNode', {
    my LibXML::Document:D $doc = $parser.parse: :$string;
    my LibXML::Document:D $dclone = $doc.cloneNode(:deep);
    ok ! $dclone.isSameNode($doc), '.isSameNode() on cloned node';
    ok $dclone.getDocumentElement();
    ok $doc.Str() eq $dclone.Str();

    my $clone = $doc.cloneNode(:!deep); # shallow
    ok ! $clone.isSameNode($doc);
    ok ! $clone.getDocumentElement().defined;
    $doc.getDocumentElement().unbindNode();
    # allow
    is $doc.Str, $clone.Str, "unbind of document element";
}

subtest 'attribute child nodes' => {
    plan 3;
    my LibXML::Document:D $doc .= parse: :file<samples/dtd.xml>;
    my $elem = $doc.createElement: "Test";
    my LibXML::Attr:D $att .= new: :name<att>, :value('xxx');
    $att.addChild: $doc.createEntityReference('foo');
    is $att.Str, "xxx test ";
    isa-ok $att.childNodes[1], 'LibXML::EntityRef';
    $elem.setAttributeNode($att);
    is $elem.Str, '<Test att="xxx&foo;"/>';
}
