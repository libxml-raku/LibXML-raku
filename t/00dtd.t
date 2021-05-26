use v6;
use Test;
plan 6;
use LibXML;
use LibXML::Attr;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Element;
use LibXML::Enums;
use LibXML::ErrorHandling;

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

##warn $dtd.Str;
##warn $doc.getInternalSubset.Str;
