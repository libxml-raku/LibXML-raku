use v6;
use Test;
plan 9;

use LibXML;
use LibXML::Enums;
use LibXML::Document;
use LibXML::Dtd;

my $htmlPublic = "-//W3C//DTD XHTML 1.0 Transitional//EN";
my $htmlSystem = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

subtest 'internalSubset', {
    my $doc = LibXML::Document.new;
    my $dtd = $doc.createExternalSubset( "html",
                                          $htmlPublic,
                                          $htmlSystem
                                        );
    ok $dtd.isSameNode(  $doc.externalSubset );
    is $dtd.publicId, $htmlPublic;
    is $dtd.systemId, $htmlSystem;
    is $dtd.name, 'html';
    ok $dtd.is-XHTML, 'is-XHTML';
}

subtest 'externalSubset', {
    my $doc = LibXML::Document.new;
    my $dtd = $doc.createInternalSubset( "html",
                                          $htmlPublic,
                                          $htmlSystem
                                        );
    ok $dtd.isSameNode( $doc.internalSubset );
    ok !defined($doc.externalSubset);

    dies-ok {$doc.setExternalSubset( $dtd, :validate )}, 'setExternalSubset :validate';
    ok defined(!$doc.externalSubset);
    ok defined($doc.internalSubset);
    lives-ok {$doc.setExternalSubset( $dtd )}, 'setExternalSubset';
    ok $dtd.isSameNode( $doc.externalSubset );
    ok defined($doc.externalSubset);
    ok !defined($doc.internalSubset);

    is $dtd.getPublicId, $htmlPublic;
    is $dtd.getSystemId, $htmlSystem;

    $doc.setInternalSubset( $dtd );
    ok !defined($doc.externalSubset);
    ok $dtd.isSameNode( $doc.internalSubset );

    my $dtd2 = $doc.createDTD( "huhu",
                                "-//W3C//DTD XHTML 1.0 Transitional//EN",
                                "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
                              );

    $doc.setInternalSubset( $dtd2 );
    ok !defined($dtd.parentNode);
    ok $dtd2.isSameNode( $doc.internalSubset );


    my $dtd3 = $doc.removeInternalSubset;
    ok $dtd3.isSameNode($dtd2);
    ok !defined($doc.internalSubset);

    $doc.setExternalSubset( $dtd2 );

    $dtd3 = $doc.removeExternalSubset;
    ok $dtd3.isSameNode($dtd2);
    ok !defined($doc.externalSubset);
}

subtest 'doc with internal subset', {
    my $parser = LibXML.new();

    my $doc = $parser.parse: :file( "samples/dtd.xml" );

    ok $doc.defined;

    my $dtd = $doc.internalSubset;
    is $dtd.name, 'doc';
    is $dtd.publicId, Str;
    is $dtd.systemId, Str;
    nok $dtd.is-XHTML, "isn't XHTML";

    my $entity-ref = $doc.createEntityReference( "foo" );
    ok $entity-ref.defined;
    is $entity-ref.nodeType, +XML_ENTITY_REF_NODE;
    ok $entity-ref.hasChildNodes;
    is $entity-ref.firstChild.nodeType, +XML_ENTITY_DECL;
    is $entity-ref.firstChild.nodeValue, " test ";
    is $entity-ref.firstChild.entityType, +XML_INTERNAL_GENERAL_ENTITY;
    isa-ok $entity-ref[0], 'LibXML::Dtd::Entity';
    isa-ok $entity-ref[0].parent, 'LibXML::Dtd';

    my $edcl = $entity-ref.firstChild;
    is $edcl.Str.chomp, '<!ENTITY foo " test ">';
    is $edcl.previousSibling.nodeType, +XML_ATTRIBUTE_DECL;
    is $edcl.previousSibling.Str.chomp, '<!ATTLIST doc type CDATA #IMPLIED>';

    my $entity = $doc.getEntity('foo');
    ok $entity.defined, 'got dtd entity';
    is $entity.nodeType, +XML_ENTITY_DECL, 'entity decl node type';
    is $entity.name, 'foo', 'entity decl name';
    is $entity.entityType, +XML_INTERNAL_GENERAL_ENTITY, 'entity decl type';
    ok $entity-ref.firstChild.isSameNode($entity), 'entity reference checks out';
    nok $doc.getEntity('bar').defined, 'get on unknown entity';

    $entity = $doc.getEntity('lt');
    ok $entity.defined, 'got predefined entity';
    is $entity.nodeType, +XML_ENTITY_DECL, 'predefined entity node type';
    is $entity.entityType, +XML_INTERNAL_PREDEFINED_ENTITY, 'predefined entity entity-type';

    $entity-ref = $doc.createEntityReference("gt");
    is($entity-ref.nodeType, +XML_ENTITY_REF_NODE, 'predefined entity reference nodeType' );
    is($entity-ref.firstChild.entityType, +XML_INTERNAL_PREDEFINED_ENTITY, 'predefined entity reference entity-type');

    {
        my $doc2  = LibXML::Document.new;
        my $e = $doc2.createElement("foo");
        $doc2.setDocumentElement( $e );

        my $dtd2 = $doc.internalSubset;
        ok $dtd2.defined;

        lives-ok {
            $doc2.setInternalSubset( $dtd2 );
            $e.appendChild( $entity-ref );
        }
    }
}

subtest 'basic DtD validation', {
    my $parser = LibXML.new();
    $parser.validation = True;
    $parser.keep-blanks = True;
    my $doc = $parser.parse: :string(q:to<EOF>);
    <?xml version='1.0'?>
    <!DOCTYPE test [
     <!ELEMENT test (#PCDATA)>
    ]>
    <test>
    </test>
    EOF

    ok $doc.validate(), 'validate()';
    ok $doc.is-valid(), 'is-valid()';
    ok $doc.is-valid(dtd => $doc.documentElement), 'is-valid($root)';
    ok $doc.is-valid(dtd => $doc.getInternalSubset), 'is-valid($dtd)';
    ok $doc.is-valid($doc.createElement('test')), 'is-valid($elem)';
    nok $doc.is-valid($doc.createElement('crud')), '!is-valid($elem)';
    nok $doc.getInternalSubset.is-XHTML, 'is-XHTML';

}

subtest 'XHTML external subset', {
    my $parser = LibXML.new();

    my $xml = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://localhost/does_not_exist.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml"><head><title>foo</title></head><body><p>bar</p></body></html>';
    my $doc;
    lives-ok {
        $doc = $parser.parse: :string($xml);
    };

    ok $doc.defined;
    ok $doc.getInternalSubset.is-XHTML, 'is-XHTML';
}

subtest 'bad Dtd parse', {
    my $bad = 'samples/bad.dtd';
    ok $bad.IO.f;
    dies-ok {
        LibXML::Dtd.parse("-//Foo//Test DTD 1.0//EN", $bad);
    };

    my $dtd = $bad.IO.slurp;

    ok $dtd.chars > 5;
    dies-ok { LibXML::Dtd.parse: :string($dtd); }, 'Parse fails for bad.dtd';

    my $xml = "<!DOCTYPE test SYSTEM \"samples/bad.dtd\">\n<test/>";

    {
        my $parser = LibXML.new;
        $parser.load-ext-dtd = False;
        $parser.validation = False;
        my $doc = $parser.parse: :string($xml);
        ok $doc.defined;
    }
    {
        my $parser = LibXML.new;
        $parser.load-ext-dtd = True;
        $parser.validation = False;
        dies-ok { $parser.parse: :string($xml) };
    }
}

subtest 'Dtd DOM', {
    my $parser = LibXML.new();
    my $string =q:to<EOF>;
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE test [
    <!ELEMENT test (#PCDATA)>
    <!ATTLIST test attr CDATA #IMPLIED>
    <!ATTLIST orphan attr2 CDATA #IMPLIED>
    ]>
    <test>
    </test>
    EOF
    my $doc = $parser.parse: :$string;
    my $dtd = $doc.internalSubset;

    nok $dtd.hasAttributes, 'hasAttributes';
    nok $dtd.attributes, 'attributes NO-OP on DTD nodes';

    my $elem-decls = $dtd.element-declarations;
    is $elem-decls<test>.gist.chomp, '<!ELEMENT test (#PCDATA)>';
    nok $elem-decls<orphan>.defined;
    is-deeply $elem-decls.keys.sort, ("orphan", "test");
    my $attr-decls = $dtd.attribute-declarations;

    my $attr-decl = $attr-decls<test><attr>;
    ok $attr-decl.defined;
    is $attr-decl.gist.chomp, '<!ATTLIST test attr CDATA #IMPLIED>';
    is $attr-decl.elemName, 'test';
    ok $attr-decl.parent.isSameNode($dtd);

    given $attr-decl.getElementDecl {
        ok .defined;
        is .gist.chomp, '<!ELEMENT test (#PCDATA)>';
        .parent.isSameNode($dtd);
    }

    my $attr2-decl = $attr-decls<orphan><attr2>;
    ok $attr2-decl.defined;
    is $attr2-decl.gist.chomp, '<!ATTLIST orphan attr2 CDATA #IMPLIED>';
    is $attr2-decl.elemName, 'orphan';
    nok $attr2-decl.getElementDecl.defined;
    given $dtd.getAttrDeclaration('orphan', 'attr2') {
        ok .defined;
        ok .isSameNode($attr2-decl);
        nok .isSameNode($attr-decl);
    }
    is-deeply $doc.Str.lines, $string.lines;
}

sub test_remove_dtd($test_name, &remove_sub) {
    my $parser = LibXML.new;
    my $doc    = $parser.parse: :file('samples/dtd.xml');
    my $dtd    = $doc.internalSubset;

    remove_sub($doc, $dtd);

    ok !$doc.internalSubset, "remove DTD via $test_name";
}

subtest 'remove Dtd Nodes', {
    test_remove_dtd( "unbindNode", sub ($doc, $dtd) {
                           $dtd.unbindNode;
                       } );
    test_remove_dtd( "removeChild", sub ($doc, $dtd) {
                           $doc.removeChild($dtd);
                       } );
    test_remove_dtd( "removeChildNodes", sub ($doc, $dtd) {
                           $doc.removeChildNodes;
                       } );
}

sub test_insert_dtd ($test_name, &insert_sub) {

    my $parser  = LibXML.new;
    my $src_doc = $parser.parse: :file('samples/dtd.xml');
    my $dtd     = $src_doc.internalSubset.clone;
    my $doc     = $parser.parse: :file('samples/dtd.xml');

    insert_sub($doc, $dtd);

    is $doc.internalSubset.Str, $dtd.Str, "insert DTD via $test_name";
}

subtest 'insert DTD nodes', {

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
}

