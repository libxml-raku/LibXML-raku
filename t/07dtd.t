use v6;
use Test;
plan 58;

use LibXML;
use LibXML::Enums;

my $htmlPublic = "-//W3C//DTD XHTML 1.0 Transitional//EN";
my $htmlSystem = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

{
    my $doc = LibXML::Document.new;
    my $dtd = $doc.createExternalSubset( "html",
                                          $htmlPublic,
                                          $htmlSystem
                                        );
    ok( $dtd.isSameNode(  $doc.externalSubset ), ' TODO : Add test name' );
    is( $dtd.publicId, $htmlPublic, ' TODO : Add test name' );
    is( $dtd.systemId, $htmlSystem, ' TODO : Add test name' );
    is( $dtd.name, 'html', ' TODO : Add test name' );
    ok( $dtd.is-XHTML, 'is-XHTML' );
}

{
    my $doc = LibXML::Document.new;
    my $dtd = $doc.createInternalSubset( "html",
                                          $htmlPublic,
                                          $htmlSystem
                                        );
    ok( $dtd.isSameNode( $doc.internalSubset ), ' TODO : Add test name' );

    $doc.setExternalSubset( $dtd );
    ok(!defined($doc.internalSubset), ' TODO : Add test name' );
    ok( $dtd.isSameNode( $doc.externalSubset ), ' TODO : Add test name' );


    is( $dtd.getPublicId, $htmlPublic, ' TODO : Add test name' );
    is( $dtd.getSystemId, $htmlSystem, ' TODO : Add test name' );

    $doc.setInternalSubset( $dtd );
    ok(!defined($doc.externalSubset), ' TODO : Add test name' );
    ok( $dtd.isSameNode( $doc.internalSubset ), ' TODO : Add test name' );

    my $dtd2 = $doc.createDTD( "huhu",
                                "-//W3C//DTD XHTML 1.0 Transitional//EN",
                                "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
                              );

    $doc.setInternalSubset( $dtd2 );
    ok( !defined($dtd.parentNode), ' TODO : Add test name' );
    ok( $dtd2.isSameNode( $doc.internalSubset ), ' TODO : Add test name' );


    my $dtd3 = $doc.removeInternalSubset;
    ok( $dtd3.isSameNode($dtd2), ' TODO : Add test name' );
    ok( !defined($doc.internalSubset), ' TODO : Add test name' );

    $doc.setExternalSubset( $dtd2 );

    $dtd3 = $doc.removeExternalSubset;
    ok( $dtd3.isSameNode($dtd2), ' TODO : Add test name' );
    ok( !defined($doc.externalSubset), ' TODO : Add test name' );
}

{
    my $parser = LibXML.new();

    my $doc = $parser.parse: :file( "example/dtd.xml" );


    ok($doc, ' TODO : Add test name');

    my $dtd = $doc.internalSubset;
    is( $dtd.name, 'doc', ' TODO : Add test name' );
    is( $dtd.publicId, Str, ' TODO : Add test name' );
    is( $dtd.systemId, Str, ' TODO : Add test name' );
    nok( $dtd.is-XHTML, 'is-XHTML' );

    my $entity = $doc.createEntityReference( "foo" );
    ok($entity, ' TODO : Add test name');
    is($entity.nodeType, +XML_ENTITY_REF_NODE, ' TODO : Add test name' );


    ok( $entity.hasChildNodes, ' TODO : Add test name' );
    # We don't have explicit EntityDecl or ElementDecl classes yet
    is( $entity.firstChild.nodeType, +XML_ENTITY_DECL, ' TODO : Add test name' );
    is( $entity.firstChild.nodeValue, " test ", ' TODO : Add test name' );

    my $edcl = $entity.firstChild;
    is( $edcl.previousSibling.nodeType, +XML_ATTRIBUTE_DECL, ' TODO : Add test name' );

    {
        my $doc2  = LibXML::Document.new;
        my $e = $doc2.createElement("foo");
        $doc2.setDocumentElement( $e );

        my $dtd2 = $doc.internalSubset.cloneNode(:deep);
        ok($dtd2, ' TODO : Add test name');

        $doc2.setInternalSubset( $dtd2 );

        $e.appendChild( $entity );
    }
}

{
    my $parser = LibXML.new();
    $parser.validation = True;
    $parser.keep-blanks = True;
    my $doc=$parser.parse: :string(q:to<EOF>);
<?xml version='1.0'?>
<!DOCTYPE test [
 <!ELEMENT test (#PCDATA)>
]>
<test>
</test>
EOF

    ok($doc.validate(), ' TODO : Add test name');
    ok($doc.is-valid(), ' TODO : Add test name');
    nok($doc.getInternalSubset.is-XHTML, 'is-XHTML');

}

{
    my $parser = LibXML.new();

    my $xml = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://localhost/does_not_exist.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml"><head><title>foo</title></head><body><p>bar</p></body></html>';
    my $doc;
    lives-ok {
        $doc = $parser.parse: :string($xml);
    }, ' TODO : Add test name';

    ok($doc.defined, ' TODO : Add test name');
    ok($doc.getInternalSubset.is-XHTML, 'is-XHTML');
}

{
    my $bad = 'example/bad.dtd';
    ok($bad.IO.f, ' TODO : Add test name' );
    dies-ok {
        LibXML::Dtd.parse("-//Foo//Test DTD 1.0//EN", $bad);
    }, ' TODO : Add test name';

    my $dtd = $bad.IO.slurp;

    ok( $dtd.chars > 5, ' TODO : Add test name' );
    dies-ok { LibXML::Dtd.parse: :string($dtd); }, 'Parse fails for bad.dtd';

    my $xml = "<!DOCTYPE test SYSTEM \"example/bad.dtd\">\n<test/>";

    {
        my $parser = LibXML.new;
        $parser.load-ext-dtd = False;
        $parser.validation = False;
        my $doc = $parser.parse: :string($xml);
        ok( $doc, ' TODO : Add test name' );
    }
    {
        my $parser = LibXML.new;
        $parser.load-ext-dtd = True;
        $parser.validation = False;
        dies-ok { $parser.parse: :string($xml) }, ' TODO : Add test name';
    }
}

{
    # RT #71076: https://rt.cpan.org/Public/Bug/Display.html?id=71076

    my $parser = LibXML.new();
    my $doc = $parser.parse: :string(q:to<EOF>);
<!DOCTYPE test [
 <!ELEMENT test (#PCDATA)>
 <!ATTLIST test
  attr CDATA #IMPLIED
 >
]>
<test>
</test>
EOF
    my $dtd = $doc.internalSubset;

    nok $dtd.hasAttributes, 'hasAttributes';
    dies-ok { $dtd.attributes }, 'attributes N/A to DTD nodes';
}

# Remove DTD nodes

sub test_remove_dtd($test_name, &remove_sub) {
    my $parser = LibXML.new;
    my $doc    = $parser.parse: :file('example/dtd.xml');
    my $dtd    = $doc.internalSubset;

    remove_sub($doc, $dtd);

    ok( !$doc.internalSubset, "remove DTD via $test_name" );
}

test_remove_dtd( "unbindNode", sub ($doc, $dtd) {
    $dtd.unbindNode;
} );
test_remove_dtd( "removeChild", sub ($doc, $dtd) {
    $doc.removeChild($dtd);
} );
test_remove_dtd( "removeChildNodes", sub ($doc, $dtd) {
    $doc.removeChildNodes;
} );

# Insert DTD nodes

sub test_insert_dtd ($test_name, &insert_sub) {

    my $parser  = LibXML.new;
    my $src_doc = $parser.parse: :file('example/dtd.xml');
    my $dtd     = $src_doc.internalSubset.clone;
    my $doc     = $parser.parse: :file('example/dtd.xml');

    insert_sub($doc, $dtd);

    ok( $doc.internalSubset.isSameNode($dtd), "insert DTD via $test_name" );
}

test_insert_dtd( "insertBefore internalSubset", sub ($doc, $dtd) {
    $doc.insertBefore($dtd, $doc.internalSubset);
} );
test_insert_dtd( "insertBefore documentElement", sub ($doc, $dtd) {
    $doc.insertBefore($dtd, $doc.documentElement);
} );
test_insert_dtd( "insertAfter internalSubset", sub ($doc, $dtd) {
    $doc.insertAfter($dtd, $doc.internalSubset);
} );
test_insert_dtd( "insertAfter documentElement", sub ($doc, $dtd) {
    $doc.insertAfter($dtd, $doc.documentElement);
} );
test_insert_dtd( "replaceChild internalSubset", sub ($doc, $dtd) {
    $doc.replaceChild($dtd, $doc.internalSubset);
} );
test_insert_dtd( "replaceChild documentElement", sub ($doc, $dtd) {
    $doc.replaceChild($dtd, $doc.documentElement);
} );
test_insert_dtd( "replaceNode internalSubset", sub ($doc, $dtd) {
    $doc.internalSubset.replaceNode($dtd);
} );
test_insert_dtd( "replaceNode documentElement", sub ($doc, $dtd) {
    $doc.documentElement.replaceNode($dtd);
} );
test_insert_dtd( "appendChild", sub ($doc, $dtd) {
    $doc.appendChild($dtd);
} );
test_insert_dtd( "addSibling internalSubset", sub ($doc, $dtd) {
    $doc.internalSubset.addSibling($dtd);
} );
test_insert_dtd( "addSibling documentElement", sub ($doc, $dtd) {
    $doc.documentElement.addSibling($dtd);
} );

