use v6;
use Test;
plan 14;
use LibXML;
use LibXML::Attr;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Element;
use LibXML::Enums;
use LibXML::ErrorHandling;
use LibXML::Entity;
use LibXML::Dtd::ElementDecl;
use LibXML::Dtd::Notation;

my $string = q:to<EOF>;
    <!ELEMENT doc (head, descr)>
    <!ELEMENT head (#PCDATA)>
    <!ATTLIST head
      id NMTOKEN #REQUIRED
      a CDATA    #IMPLIED
      b CDATA    'inherited'
    >
    <!ELEMENT descr (#PCDATA)>
EOF

my LibXML::Dtd $dtd .= parse: :$string;

my $level;
my $message;
use LibXML::SAX::Handler::SAX2;
class SaxHandler is LibXML::SAX::Handler::SAX2 {
    use LibXML::SAX::Builder :sax-cb;
    method serror(X::LibXML $_) is sax-cb {
        $level = .level;
        $message = .msg.chomp;
    }
}

$string = qq:to<EOF>;
<!DOCTYPE doc [ $string ]>
<doc>
    <head id="explicit">A Test</head>
    <descr>
        ^^ attribute "id" has been given a value, as required
        ^^ attribute "a" has implied value CDATA
        ^^ attribute "b" has default value 'bless'
    </descr>
</doc>
EOF

my LibXML::Document $doc .= parse: :$string, :dtd;
my LibXML::Element $head = $doc.documentElement.elements[0];
is-deeply $head.keys.sort, ("\@b", "\@id", "text()");
my LibXML::Attr $id = $head.getAttributeNode('id');
my LibXML::Attr $a = $head.getAttributeNode('a');
my LibXML::Attr $b = $head.getAttributeNode('b');

is $id.value, 'explicit';
is-deeply $a.value, Str;
is $b.value, 'inherited';

my SaxHandler $sax-handler .= new();  

$doc .= parse( string => q:to<EOF>, :load-ext-dtd, :$sax-handler, :suppress-warnings);
    <!DOCTYPE test PUBLIC "-//TEST" "test.dtd" []>
    <test>
      <title>T1</title>
    </test>
EOF

is $level, +XML_ERR_WARNING;
is $message, 'failed to load external entity "test.dtd"';

subtest 'doc with internal dtd' => {
    plan 8;
    $doc .= parse: :file<test/dtd/note-internal-dtd.xml>;
    nok $doc.getExternalSubset.defined, 'no external DtD';
    my LibXML::Dtd $dtd = $doc.getInternalSubset;
    ok $dtd.defined, 'has DtD';
    ok $dtd.validate, 'validate';
    ok $doc.validate;
    is $dtd.name, "note", '.name';
    nok $dtd.systemId.defined, 'sans systemId';
    nok $dtd.publicId.defined, 'sans publicId';
    is-deeply $dtd.is-XHTML, Bool, 'is-XHTML';
}

subtest 'doc with external dtd loaded' => {
    plan 8;
    $doc .= parse: :file<test/dtd/note-external-dtd.xml>, :dtd;
    ok $doc.getExternalSubset.defined, 'external DtD';
    my LibXML::Dtd $dtd = $doc.getInternalSubset;
    ok $dtd.defined, 'has DtD';
    ok $doc.validate($dtd), 'doc.validate';
    ok $dtd.validate($doc), 'dtd.validate';
    is $dtd.name, "note", '.name';
    is $dtd.systemId, "note.dtd", 'systemId';
    nok $dtd.publicId.defined, 'sans publicId';
    is-deeply $dtd.is-XHTML, False, 'is-XHTML';
}

subtest 'doc with no dtd loaded' => {
    plan 9;
    my LibXML::Document $other-doc .= parse: :file<test/dtd/note-external-dtd.xml>, :dtd;
    $doc .= parse: :file<test/dtd/note-no-dtd.xml>;
    dies-ok {$doc.setExternalSubset: $other-doc.getExternalSubset}, 'set uncloned Dtd';
    $doc.setExternalSubset: $other-doc.getExternalSubset.clone;
    ok $doc.getExternalSubset.defined, 'external DtD';
    my LibXML::Dtd $dtd = $doc.getExternalSubset;
    ok $dtd.defined, 'has DtD';
    ok $doc.validate($dtd), 'doc.validate';
    ok $dtd.validate($doc), 'dtd.validate';
    is $dtd.name, "note", '.name';
    is $dtd.systemId, "note.dtd", 'systemId';
    nok $dtd.publicId.defined, 'sans publicId';
    is-deeply $dtd.is-XHTML, False, 'is-XHTML';
}

subtest 'dtd notations' => {
    plan 9;
    $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::DeclMap $notations = $dtd.notations;
    ok $notations.defined, 'DtD has notations';
    is-deeply $notations.keys, ("foo",), 'notation keys';
    my LibXML::Dtd::Notation $foo = $notations<foo>;
    ok $foo.defined, "notation fetch";
    is $foo.name, "foo", 'notation name';
    is $foo.systemId, 'bar', 'notation system-Id';
    is-deeply $foo.publicId, Str, 'notation public-Id';
    is $foo.Str.chomp, '<!NOTATION foo SYSTEM "bar" >', 'notation Str';
    ok $foo.isSameNode($foo);
    nok $foo.isSameNode(LibXML::Dtd::Notation.new: :name<bar>);
}

subtest 'dtd entities' => {
    plan 10;
    $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::DeclMap $entities = $dtd.entities;
    ok $entities.defined, 'DtD has entities';
    is-deeply $entities.keys.sort, ("foo", "unparsed"), 'entity keys';
    my LibXML::Entity $foo = $entities<foo>;
    ok $foo.defined, "entity fetch";
    is $foo.name, "foo", 'entity name';
    is $foo.value, ' test ', 'entity value';
    my LibXML::Entity $unparsed = $entities<unparsed>;
    is-deeply $unparsed.systemId, 'http://example.org/blah', 'entity system-Id';
    is-deeply $unparsed.publicId, Str, 'entity public-Id';
    is $unparsed.notationName, "foo", 'notation name';
    is $unparsed.Str.chomp, '<!ENTITY unparsed SYSTEM "http://example.org/blah" NDATA foo>', 'entity Str';
    # no update support yet
    throws-like {$entities<bar> = $foo}, X::NYI, 'entities hash update is nyi';
}

subtest 'dtd element declarations' => {
    plan 13;
    $doc .= parse: :file<test/dtd/note-internal-dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::DeclMap $elements = $dtd.element-declarations;
    ok $elements.defined, 'DtD has elements';
    is-deeply $elements.keys.sort, ("body", "from", "heading", "note", "to"), 'element decl keys';
    isa-ok $elements.values[0], LibXML::Dtd::ElementDecl, 'values type';
    isa-ok $elements.pairs[0].value, LibXML::Dtd::ElementDecl, 'pairs type';
    my LibXML::Dtd::ElementDecl $note-decl = $elements<note>;
    ok $note-decl.defined, "element decl fetch";
    is $note-decl.name, 'note', 'element decl name';
    is $note-decl.type, +XML_ELEMENT_DECL, 'element decl type';
    is $note-decl.parent.type, +XML_DTD_NODE, 'element parent type';
    is $note-decl.Str.chomp, '<!ELEMENT note (to , from , heading , body)>', 'element decl string';
    ok $dtd.getNodeDeclaration($doc.documentElement).isSameNode($note-decl), 'getNodeDeclaration';
    my LibXML::Dtd::ElementDecl $to-decl = $elements<to>;
    is $to-decl.name, 'to', 'element decl name';
    is $to-decl.type, +XML_ELEMENT_DECL, 'element decl type';
    is $to-decl.parent.type, +XML_DTD_NODE, 'element parent type';
}

subtest 'dtd attribute declarations' => {
    plan 4;
    $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::AttrDeclMap $elem-attributes = $dtd.element-attribute-declarations;
    is-deeply $elem-attributes.keys, ("doc",), 'elem attribute keys';
    my LibXML::Dtd::DeclMap $doc-attributes = $elem-attributes<doc>;
    is-deeply $doc-attributes.keys, ("type",), 'attlist keys';
    isa-ok $elem-attributes.values[0], LibXML::Dtd::DeclMap, 'values type';
    my LibXML::Dtd::AttrDecl $type-attr = $doc-attributes<type>;
    is $type-attr.Str.chomp, '<!ATTLIST doc type CDATA #IMPLIED>', 'attlist Str';
}

subtest 'dtd namespaces' => {
    plan 10;
    $doc .= parse: :file<test/dtd/namespaces.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my $element-declarations = $dtd.element-declarations;
    is-deeply $element-declarations.keys.sort, ("foo:A", "foo:B"), "element decls";
    my LibXML::Dtd::ElementDecl:D $foo:A-decl = $element-declarations<foo:A>;
    is $foo:A-decl.Str.chomp, '<!ELEMENT foo:A (foo:B)>';
    my LibXML::Dtd::AttrDeclMap $elem-attributes = $dtd.element-attribute-declarations;
    is-deeply $elem-attributes.keys, ("foo:A",), 'elem attribute keys';
    my LibXML::Dtd::DeclMap $doc-attributes = $elem-attributes<foo:A>;
    is-deeply $doc-attributes.keys.sort, ("bar", "xmlns:foo"), 'attlist keys';
    my LibXML::Dtd::AttrDecl:D $bar-attr-decl = $doc-attributes<bar>;
    is $bar-attr-decl.Str.chomp, '<!ATTLIST foo:A bar CDATA #REQUIRED>';
    my $xmlns:foo-attr-decl = $doc-attributes<xmlns:foo>;
    is $xmlns:foo-attr-decl.Str.chomp, '<!ATTLIST foo:A xmlns:foo CDATA #FIXED "http://www.foo.org/">';
    ok $bar-attr-decl.isSameNode($bar-attr-decl);
    nok $bar-attr-decl.isSameNode($xmlns:foo-attr-decl);
    my LibXML::Element:D $foo:A-elem = $doc.documentElement;
    ok $foo:A-decl.isSameNode($dtd.getNodeDeclaration($foo:A-elem));
    my LibXML::Attr:D $bar-attr = $foo:A-elem.getAttributeNode('bar');
    ok $bar-attr-decl.isSameNode($dtd.getNodeDeclaration($bar-attr));
}
