use v6;
# ensure .column() and other error fields are correct
use Test;
use LibXML;
use LibXML::DocumentFragment;
use LibXML::Enums;
use LibXML::ErrorHandling;

plan 2;

throws-like
    {
        LibXML.parse: :string(
        '<foo attr1="value1" attr2="value2" attr3="value2" attr4="value2"'
            ~ ' attr5="value2" attr6="value2" attr7="value2" attr8="value2"'
            ~ ' attr9="value2" attr10="value2" attr11="value2" attr12="value2"'
            ~ ' attr13="value2"attr14="value2" attr15="value2" />'
        ),
            :URI<test.xml>,
    },
    X::LibXML::Parser,
    "XML_ERR_DOCUMENT_END",
    :file<test.xml>,
    :line(1),
    :level(XML_ERR_FATAL),
    :code(XML_ERR_DOCUMENT_END),
    :domain-num(XML_FROM_PARSER),
    :domain<parser>,
    :column({ LibXML.version < v2.09.02 || 203 }), # The older versions are unreliable, make it just True
    :msg(*.contains('Extra content at the end of the document')),
    :message(rx:s/
    'test.xml:1: parser error : attributes construct error'
    .*
    "test.xml:1: parser error : Couldn't find end of Start Tag foo line 1"
    .*
    'test.xml:1: parser error : Extra content at the end of the document'/),
    :prev({
        ?( $^prev ~~ X::LibXML::Parser
            && $prev.domain-num == XML_FROM_PARSER
            && $prev.prev.msg.chomp eq 'attributes construct error' )
    });

throws-like
    {
        LibXML::DocumentFragment.parse: :string('<foo>XX</bar>'), :balanced;
    },
    X::LibXML::Parser,
    "XML_ERR_NOT_WELL_BALANCED",
    :file(Str:U),
    :line(1),
    :level(XML_ERR_FATAL),
    :code(XML_ERR_NOT_WELL_BALANCED),
    :column({ LibXML.version < v2.09.02 || 13 }),
    :domain-num(XML_FROM_PARSER),
    :domain<parser>,
    :msg(*.contains('chunk is not well balanced')),
    :message(rx:s/
    ':1: parser error : Opening and ending tag mismatch: foo line 1 and bar'
    .*
    ':1: parser error : chunk is not well balanced'
    .* /),
    :prev({
        $^prev ~~ X::LibXML::Parser
        && $prev.domain-num == XML_FROM_PARSER
        && $prev.msg.chomp eq 'Opening and ending tag mismatch: foo line 1 and bar'
    });
