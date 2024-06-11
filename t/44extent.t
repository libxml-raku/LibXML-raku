use v6;
use Test;
use LibXML;
use LibXML::Config;
use LibXML::Enums;

constant config = LibXML::Config;

plan 7;

config.external-entity-loader = &handler;

my LibXML $parser .= new: :expand-entities;

$parser.config.parser-locking = True;

sub handler(*@p) {
    return @p.map({$_//''}).join: ',';
}

my $xml = q:to<EOF>;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [
<!ENTITY a PUBLIC "//foo/bar/b" "file:/dev/null">
<!ENTITY b SYSTEM "file:///dev/null">
]>
<root>
  <a>&a;</a>
  <b>&b;</b>
</root>
EOF
my $xml_out = $xml;
$xml_out .= subst('&a;', 'file:/dev/null,//foo/bar/b', :g);
$xml_out .= subst('&b;', 'file:///dev/null,', :g);

my $doc = $parser.parse: :string($xml);

is $doc.Str(), $xml_out;

my $xml_out2 = $xml; $xml_out2 .= subst(/'&'[a|b]';'/, '<!-- -->', :g);

$parser.config.external-entity-loader = -> *@ { '<!-- -->' };
$doc = $parser.parse: :string($xml);
is $doc.Str(), $xml_out2;

config.external-entity-loader = -> *@ { '' }

$parser.set-options(
    expand_entities => 0,
    recover => 2,
);
$doc = $parser.parse: :string($xml);
is $doc.Str(), $xml;

for $doc.findnodes('/root/*') -> $el {
    ok $el.hasChildNodes;
    is $el.firstChild.nodeType, +XML_ENTITY_REF_NODE;
}

