use v6;
use Test;
use LibXML;
use LibXML::Config;
constant config =  LibXML::Config;

plan 1;

sub handler(*@p) {
  "ENTITY:" ~ @p.map({$_//''}).join: ',';
}

# global entity loader
config.external-entity-loader = &handler;

my LibXML $parser .= new: :expand-entities;

$parser.config.parser-locking = True;

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
$xml_out ~~ s|'&a;'|ENTITY:file:/dev/null,//foo/bar/b|;
$xml_out ~~ s|'&b;'|ENTITY:file:///dev/null,|;

my $doc = $parser.parse: :string($xml);

is $doc.Str, $xml_out;
