use v6;
use Test;
use LibXML;
use LibXML::Attr;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Element;
use LibXML::Enums;
use LibXML::ErrorHandling;

plan 11;

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

my LibXML::Document:D $doc .= parse: :$string, :dtd;
my LibXML::Element:D $head = $doc.documentElement.elements[0];
is-deeply $head.keys.sort, ("\@b", "\@id", "text()");
my LibXML::Attr $id = $head.getAttributeNode('id');
my LibXML::Attr $a = $head.getAttributeNode('a');
my LibXML::Attr $b = $head.getAttributeNode('b');

is $id.value, 'explicit';
is-deeply $a.value, Str;
is $b.value, 'inherited';

my SaxHandler $sax-handler .= new();  

quietly {
    $doc .= parse( string => q:to<EOF>, :load-ext-dtd, :$sax-handler);
        <!DOCTYPE test PUBLIC "-//TEST" "test.dtd" []>
        <test>
          <title>T1</title>
        </test>
    EOF
}
is $level, +XML_ERR_WARNING;
like $message, rx/'failed to load'.*'"test.dtd"'/;

subtest 'doc with internal dtd' => {
    plan 14;
    $doc .= parse: :file<test/dtd/note-internal-dtd.xml>;
    nok $doc.getExternalSubset.defined, 'no external DtD';
    subtest 'Internal Dtd hidden from associative interface', {
        plan 3;
        is-deeply $doc.keys, ('note', ), 'doc keys';
        is $doc<note>.elems, 1, 'doc root elems';
        isa-ok $doc<note>[0], LibXML::Element, 'doc root dereference';
    }
    my LibXML::Dtd $dtd = $doc.getInternalSubset;
    ok $dtd.defined, 'has internal DtD';
    ok $dtd.validate, 'validate';
    ok $doc.validate;
    is $dtd.name, "note", '.name';
    nok $dtd.systemId.defined, 'sans systemId';
    nok $dtd.publicId.defined, 'sans publicId';
    is-deeply $dtd.is-XHTML, Bool, 'is-XHTML';
    is $dtd.keys.sort.join(' '), 'body from heading note to', 'keys';
    my $note = $dtd<note>;
    is $note.gist.chomp, '<!ELEMENT note (to , from , heading , body)>';
    is $note.keys.join(' '), "@id to from heading body";
    is $note<@id>.gist.chomp, '<!ATTLIST note id CDATA #IMPLIED>';
    is $note<to>.gist.chomp, '<!ELEMENT to (#PCDATA)>';
    
}

subtest 'doc with external dtd loaded' => {
    plan 8;
    $doc .= parse: :file<test/dtd/note-external-dtd.xml>, :dtd;
    ok $doc.getExternalSubset.defined, 'external DtD';
    my LibXML::Dtd $dtd = $doc.getInternalSubset;
    ok $dtd.defined, 'has internal DtD';
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
    lives-ok {$doc.setExternalSubset: $other-doc.getExternalSubset}, 'copy external subset';
    $doc.setExternalSubset: $other-doc.getExternalSubset;
    ok $doc.getExternalSubset.defined, 'external DtD';
    my LibXML::Dtd $dtd = $doc.getExternalSubset;
    ok $dtd.defined, 'has external DtD';
    ok $doc.validate($dtd), 'doc.validate';
    ok $dtd.validate($doc), 'dtd.validate';
    is $dtd.name, "note", '.name';
    is $dtd.systemId, "note.dtd", 'systemId';
    nok $dtd.publicId.defined, 'sans publicId';
    is-deeply $dtd.is-XHTML, False, 'is-XHTML';
}

subtest 'doc with parameter entities' => {
    plan 8;
    my LibXML::Document $doc .= parse: :file<test/dtd/parameter-entities.xml>, :dtd;
    ok $doc.internalSubset.defined, "has internal subset";
    my LibXML::Dtd $dtd = $doc.getExternalSubset;
    ok $dtd.defined, 'has external DtD';
    ok $doc.validate, 'doc.validate';
    ok $doc.validate($dtd), 'doc.validate(dtd)';
    ok $dtd.validate($doc), 'dtd.validate';
    is $dtd.name, "Document", '.name';
    is $dtd.systemId, "parameter-entities.dtd", 'systemId';
    nok $dtd.publicId.defined, 'sans publicId';
}

subtest 'Dtd parse' => {
    lives-ok {LibXML::Dtd.parse: :system-id<samples/ProductCatalog.dtd>};
    if LibXML::Config.version >= v2.14.00 {
        throws-like { LibXML::Dtd.parse: :system-id<samples/DoesNotExist.dtd> }, X::LibXML::Parser;
    }
    else {
        skip "requires libxml2 >= v2.14.00";
    }

}

