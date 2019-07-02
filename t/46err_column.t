#!/usr/bin/perl
# Bug #66642 for XML-LibXML: $err->column() incorrectly maxed out as 80
# https://rt.cpan.org/Public/Bug/Display.html?id=66642 .

use Test;
use LibXML;
use LibXML::Enums;

plan 11;

try {
    LibXML.new.parse: :string(
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
is $err.level, +XML_ERR_FATAL, 'level is OK';
is $err.code, +XML_ERR_SPACE_REQUIRED, 'code is OK';
is $err.column(), 204, "Column is OK.";
is $err.domain, +XML_FROM_PARSER;
is $err.domain-name, 'parser';
is $err.msg.chomp, 'attributes construct error';
is $err.message, 'test.xml:1: parser error : attributes construct error';
