use Test;
use LibXML;
use LibXML::Config;
constant config =  LibXML::Config;

plan 1;

if LibXML.version < v2.06.27 {
    skip-rest("skipping for libxml2 < 2.6.27");
    exit;
}

sub handler(*@p) {
    warn;
  "ENTITY:" ~ @p.map({$_//''}).join: ',';
}

# global entity loader
config.external-entity-loader = &handler;

my $parser = LibXML.new(expand_entities => 1);

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

# TEST
is( $doc.Str, $xml_out );
