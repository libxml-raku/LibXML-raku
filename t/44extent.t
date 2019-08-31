use Test;
use LibXML;
use LibXML::Config;
use LibXML::Enums;

constant config =  LibXML::Config;

plan 7;

config.external-entity-loader = &handler;

my $parser = LibXML.new(
  expand_entities => 1,
);

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

# TEST
is( $doc.Str(), $xml_out, ' TODO : Add test name' );

my $xml_out2 = $xml; $xml_out2 .= subst(/'&'[a|b]';'/, '<!-- -->', :g);

config.external-entity-loader = -> *@ { '<!-- -->' };
$doc = $parser.parse: :string($xml);
# TEST
is( $doc.Str(), $xml_out2, ' TODO : Add test name' );

config.external-entity-loader = -> *@ { '' }

$parser.set-options(
  expand_entities => 0,
  recover => 2,
);
$doc = $parser.parse: :string($xml);
# TEST
is( $doc.Str(), $xml, ' TODO : Add test name' );

# TEST:$el=2;
for $doc.findnodes('/root/*') -> $el {
  # TEST*$el
  ok ($el.hasChildNodes, ' TODO : Add test name');
  # TEST*$el
  ok ($el.firstChild.nodeType == XML_ENTITY_REF_NODE, ' TODO : Add test name');
}

