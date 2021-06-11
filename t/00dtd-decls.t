use Test;
plan 6;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Enums;
use LibXML::Dtd::ElementDecl;
use LibXML::Dtd::Entity;
use LibXML::Dtd::Notation;

subtest 'dtd notations' => {
    plan 9;
    my LibXML::Document $doc .= parse: :file<example/dtd.xml>;
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
    my LibXML::Document $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::DeclMap $entities = $dtd.entities;
    ok $entities.defined, 'DtD has entities';
    is-deeply $entities.keys.sort, ("foo", "unparsed"), 'entity keys';
    my LibXML::Dtd::Entity $foo = $entities<foo>;
    ok $foo.defined, "entity fetch";
    is $foo.name, "foo", 'entity name';
    is $foo.value, ' test ', 'entity value';
    my LibXML::Dtd::Entity $unparsed = $entities<unparsed>;
    is-deeply $unparsed.systemId, 'http://example.org/blah', 'entity system-Id';
    is-deeply $unparsed.publicId, Str, 'entity public-Id';
    is $unparsed.notationName, "foo", 'notation name';
    is $unparsed.Str.chomp, '<!ENTITY unparsed SYSTEM "http://example.org/blah" NDATA foo>', 'entity Str';
    # no update support yet
    throws-like {$entities<bar> = $foo}, X::NYI, 'entities hash update is nyi';
}

subtest 'dtd element declarations' => {
    plan 15;
    my LibXML::Document $doc .= parse: :file<test/dtd/note-internal-dtd.xml>;
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
    is-deeply $note-decl.content.potential-children, ["to", "from", "heading", "body"];
    is $note-decl.Str.chomp, '<!ELEMENT note (to , from , heading , body)>', 'element decl string';
    is $note-decl.attributes<id>.Str.chomp, '<!ATTLIST note id CDATA #IMPLIED>', 'attributes string';
    ok $dtd.getNodeDeclaration($doc.documentElement).isSameNode($note-decl), 'getNodeDeclaration';
    my LibXML::Dtd::ElementDecl $to-decl = $elements<to>;
    is $to-decl.name, 'to', 'element decl name';
    is $to-decl.type, +XML_ELEMENT_DECL, 'element decl type';
    is $to-decl.parent.type, +XML_DTD_NODE, 'element parent type';
}

subtest 'dtd element declaration content' => {
    plan 7;
    my LibXML::Document $doc .= parse: :file<test/dtd/note-internal-dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::ElementDecl:D $note-decl = $dtd.element-declarations<note>;
    my LibXML::Dtd::ElementDecl:D $to-decl = $dtd.element-declarations<to>;
    given $note-decl.content -> LibXML::Dtd::ElementDecl::Content:D $_ {
        is .type, +XML_ELEMENT_CONTENT_SEQ, 'type';
        is .arity, 1, 'arity';
        is .Str, '(to , from , heading , body)', 'Str';
        given .firstChild {
            is .type, +XML_ELEMENT_CONTENT_ELEMENT, 'firstChild type';
            is .Str, 'to', 'firstChild Str';
            ok $to-decl.isSameNode(.getElementDecl), 'firstChild getElementDecl';
        }
        is $to-decl.content.Str, '#PCDATA', 'to decl Str';
    }
}

subtest 'dtd attribute declarations' => {
    plan 4;
    my LibXML::Document $doc .= parse: :file<example/dtd.xml>;
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
    my LibXML::Document $doc .= parse: :file<test/dtd/namespaces.xml>;
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
