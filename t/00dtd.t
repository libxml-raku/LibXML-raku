use v6;
use Test;
plan 2;
use LibXML;
use LibXML::Dtd;
use LibXML::Document;
use LibXML::Enums;
use LibXML::ErrorHandling;

my LibXML::Dtd $dtd .= parse( string => q:to<EOF>);
    <!ELEMENT root (head, descr)>
    <!ELEMENT head (#PCDATA)>
    <!ATTLIST head
      id NMTOKEN #REQUIRED
      a CDATA #IMPLIED
    >
    <!ELEMENT descr (#PCDATA)>
EOF

my $level;
my $message;
use LibXML::SAX::Handler;
class SaxHandler is LibXML::SAX::Handler {
    use LibXML::SAX::Builder :sax-cb;
    method serror(X::LibXML $_) is sax-cb {
        $level = .level;
        $message = .msg.chomp;
    }
}

my SaxHandler $sax-handler .= new();  

my LibXML::Document $doc .= parse( string => q:to<EOF>, :load-ext-dtd, :$sax-handler, :suppress-warnings);
    <!DOCTYPE test PUBLIC "-//TEST" "test.dtd" []>
    <test>
      <title>T1</title>
    </test>
EOF

is $level, +XML_ERR_WARNING;
is $message, 'failed to load external entity "test.dtd"';

##warn $dtd.Str;
##warn $doc.getInternalSubset.Str;
