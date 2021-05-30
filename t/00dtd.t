use v6;
use Test;
plan 10;
use LibXML;
use LibXML::Attr;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Element;
use LibXML::Enums;
use LibXML::ErrorHandling;
use LibXML::HashMap;
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
    plan 6;
    $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::HashMap[LibXML::Dtd::Notation] $notations = $dtd.notations;
    ok $notations.defined, 'DtD has notations';
    is-deeply $notations.keys, ("foo",), 'notation keys';
    my LibXML::Dtd::Notation $foo = $notations<foo>;
    ok $foo.defined, "notation fetch";
    is $foo.name, "foo", 'notation name';
    is $foo.systemId, 'bar', 'notation system-Id';
    is-deeply $foo.publicId, Str, 'notation public-Id';
}
