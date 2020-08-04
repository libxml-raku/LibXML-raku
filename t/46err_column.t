use v6;
# ensure .column() and other error fields are correct
use Test;
use LibXML;
use LibXML::Enums;

plan 14;

try {
    LibXML.parse: :string(
'<foo attr1="value1" attr2="value2" attr3="value2" attr4="value2"'
~ ' attr5="value2" attr6="value2" attr7="value2" attr8="value2"'
~ ' attr9="value2" attr10="value2" attr11="value2" attr12="value2"'
~ ' attr13="value2"attr14="value2" attr15="value2" />'
    ),
    :URI<test.xml>,
};
my $err = $!;
ok $err.defined, 'got error';
isa-ok $err, 'X::LibXML::Parser', 'error type';
is $err.file, 'test.xml', 'File is OK.';
is $err.line, 1, 'Line is OK';
is $err.level, +XML_ERR_FATAL;
is $err.code, +XML_ERR_DOCUMENT_END, 'code is OK';
todo "column() unreliable in libxml2.version < v2.09.02"
    if LibXML.version < v2.09.02;
is $err.column(), 203, "Column is OK.";
is $err.level, +XML_ERR_FATAL, 'level is OK';
is $err.domain-num, +XML_FROM_PARSER;
is $err.domain, 'parser';
is $err.msg.chomp, 'Extra content at the end of the document';
like $err.message, rx:s/
    'test.xml:1: parser error : attributes construct error'
    .*
    "test.xml:1: parser error : Couldn't find end of Start Tag foo line 1"
    .*
    'test.xml:1: parser error : Extra content at the end of the document'
/;

is $err.prev.domain-num, +XML_FROM_PARSER;
is $err.prev.prev.msg.chomp, 'attributes construct error';
