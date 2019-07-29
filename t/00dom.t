use v6;
use Test;
plan 34;

# bootstrapping tests for the DOM

use LibXML;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Native;

my $string = "<a>    <b/> </a>";
my $tstr= "<a><b/></a>\n";
my $sDoc   = '<C/><D/>';
my $sChunk = '<A/><B/>';

my LibXML $parser .= new;
$parser.keep-blanks = False;
$parser.config.skip-xml-declaration = True;
my LibXML::Document $doc = $parser.parse: :$string;
is $doc.Str, $tstr;
is-deeply $doc.doc, $doc, 'doc self-root';

$doc .= parse: :$string, :!keep-blanks;
is $doc.Str,  $tstr;

my LibXML::DocumentFragment:D $frag = $parser.parse-balanced: :string($sDoc);
my LibXML::DocumentFragment:D $chk = $parser.parse-balanced: :string($sChunk);

lives-ok {$frag.appendChild( $chk )}, 'appendChild lives';

is( $frag.Str, '<C/><D/><A/><B/>', 'Parse/serialize fragment "<C/><D/><A/><B/>"');

# create a document from scratch
$doc .= new;
my LibXML::Element:D $root .= new: :name<Test>;
$doc.documentElement = $root;
my LibXML::Element:D $root2 = $doc.documentElement;
ok $root === $root2, 'Unique root';
is $root, '<Test/>', 'Root Element';
is ~$doc, "<Test/>\n", 'Document';
ok $root.doc.isSameNode($doc);
ok $doc.native.isSameNode($root.native.doc);

# attribute basics
my $elem = $doc.createElement('foo');
my LibXML::Attr $attr = $doc.createAttribute('attr', 'e & f');
$elem.setAttributeNode($attr);
is $attr, 'e & f', 'attr.Str';
is $elem.native.properties, ' attr="e &amp; f"', 'elem properties linkage';
is $attr.native.parent.properties, ' attr="e &amp; f"', 'attribute parent linkage';
my $att2 = $elem.getAttributeNode('attr');
is $att2.Str, 'e & f', 'att2.Str';
ok $attr.isSameNode($att2);
is($elem, '<foo attr="e &amp; f"/>', 'Elem with attribute added');
$elem.removeAttribute('attr');
$att2 = $elem.getAttributeNode('attr');
nok $att2.defined, 'getAttributeNode after removal';
is($elem.Str, '<foo/>', 'Elem with attribute removed');

my %atts := $elem.attributes;
%atts<aaa> = 'bbb';
is($elem.Str, '<foo aaa="bbb"/>', 'Elem attribute set via attributes map');
$elem.attributes = 'xxx' => 'yyy';
is($elem.Str, '<foo xxx="yyy"/>', 'Elem attribute set via attributes proxy');
$elem.attributes<xxx>:delete;
is($elem.Str, '<foo/>', 'Elem with attribute removed via attributes map');

$elem.attributes = 'x:bbb' => 'zzz';
is($elem.Str, '<foo x:bbb="zzz"/>', 'QName Elem set via attributes proxy');
$elem.attributes = %(
    'http://ns' => %('x:aaa' => 'AAA',
                     'x:bbb' => 'BBB',
                     'y:ccc' => 'CCC'),
    :foo<bar>,
   );
is($elem.Str, '<foo xmlns:x="http://ns" foo="bar" x:aaa="AAA" x:bbb="BBB" x:ccc="CCC"/>', 'NS Elem set via attributes proxy');

%atts := $elem.attributes;
is-deeply %atts.keys.sort, ('foo', 'http://ns'), 'NS entries';
is-deeply %atts<http://ns>.keys.sort, ('aaa', 'bbb', 'ccc'), 'NS sub-entries';
is %atts<foo>, 'bar', 'Non NS elem';
is %atts<http://ns><aaa>, 'AAA', 'NS elem';

my $prefix = $elem.native.genNsPrefix;
is $prefix, '_ns0', 'first generated NS prefix';
$elem.requireNamespace('http://ns2');
$prefix = $elem.native.genNsPrefix;
is $prefix, '_ns1', 'second generated NS prefix';

lives-ok {$attr = $elem.getAttributeNodeNS('http://ns', 'aaa');};
lives-ok {%atts.setNamedItemNS('http://ns', $attr);};
dies-ok {%atts.setNamedItemNS('http://ns2', $attr);}, 'changing attribute NS; not currently supported';

lives-ok {$attr = %atts<http://ns><aaa>:delete};

is($elem.Str, '<foo xmlns:x="http://ns" xmlns:_ns0="http://ns2" foo="bar" x:bbb="BBB" x:ccc="CCC"/>', 'NS Elem after NS proxy deletion');



