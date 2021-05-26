use v6;
use Test;
plan 64;

# bootstrapping tests for the DOM

use LibXML;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Raw;
use LibXML::Node;
use NativeCall;

my $string = "<a>    <b/> <c/> </a>";
my $tstr = "<a><b/><c/></a>\n";
my $sDoc   = '<C/><D/>';
my $sChunk = '<A/><B/>';

my LibXML $parser .= new;
$parser.keep-blanks = True;
$parser.config.skip-xml-declaration = True;
my LibXML::Document $doc = $parser.parse: :$string;
isnt $doc.Str, $tstr, 'blanks kept';
ok $doc.doc === $doc, 'doc self-root';

my $a = $doc.first;
is $a.tag, 'a';
is $a.first, '    ';
is $a.first(:!blank), '<b/>';
is $a.first('node()'), '    ';
is $a.first('b'), '<b/>';
is-deeply $a.first('XX'), LibXML::Node;

is $a.last, ' ';
is $a.last(:!blank), '<c/>';
is $a.last('node()'), ' ';
is $a.last('b'), '<b/>';
is $a.last('c'), '<c/>';
is $a.elements, '<b/><c/>', 'elements()';
is-deeply $a.last('XX'), LibXML::Node;
ok $a.getOwner.isSameNode($doc);
ok $a.first('b').getOwner.isSameNode($doc);
$a.unbindNode;
ok $a.getOwner.isSameNode($a);
ok $a.first('b').getOwner.isSameNode($a);

$doc .= parse: :$string, :!keep-blanks;
is $doc.Str,  $tstr, 'blanks discarded';

my LibXML::DocumentFragment:D $frag = $parser.parse-balanced: :string($sDoc);
my LibXML::DocumentFragment:D $chk = $parser.parse-balanced: :string($sChunk);

lives-ok {$frag.appendChild( $chk )}, 'appendChild lives';

is( $frag.Str, '<C/><D/><A/><B/>', 'Parse/serialize fragment');
is $frag.elements.Str, '<C/><D/><A/><B/>', 'Fragment elements';
ok $frag<D>[0].addNewChild(Str, 'Bar').getOwner.isSameNode($frag);

# create a document from scratch
$doc .= new;
my LibXML::Element $root .= new: :name<Test>;
$doc.documentElement = $root;
my LibXML::Element $root2 = $doc.documentElement;
ok $root.unique-key eq $root2.unique-key, 'Unique root key';
ok +nativecast(Pointer, $root) == +nativecast(Pointer, $root2), 'Unique root address';
is $root, '<Test/>', 'Root Element';
is ~$doc, "<Test/>\n", 'Document';
ok $root.doc.isSameNode($doc);
ok $doc.raw.isSameNode($root.raw.doc);
ok +nativecast(Pointer, $doc.raw) == +nativecast(Pointer, $root.raw.doc);

# attribute basics
my $elem = $doc.createElement('foo');
my LibXML::Attr $attr = $doc.createAttribute('attr', 'e & f');
$elem.setAttributeNode($attr);
is $attr, 'e & f', 'attr.Str';
is $elem.raw.properties, ' attr="e &amp; f"', 'elem properties linkage';
is $attr.raw.parent.properties, ' attr="e &amp; f"', 'attribute parent linkage';
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
$elem<@xxx>:delete;
is($elem.Str, '<foo/>', 'Elem with attribute removed via attributes map');

$elem.attributes = 'x:bbb' => 'zzz';
is($elem.Str, '<foo x:bbb="zzz"/>', 'QName Elem set via attributes proxy');
$elem<@*> = %(
    'http://ns' => %('x:aaa' => 'AAA',
                     'x:bbb' => 'BBB',
                     'y:ccc' => 'CCC'),
    :foo<bar>,
   );
is($elem.Str, '<foo xmlns:x="http://ns" foo="bar" x:aaa="AAA" x:bbb="BBB" x:ccc="CCC"/>', 'NS Elem set via attributes proxy');
is $elem<@foo>, 'bar';
is $elem<@x:aaa>, 'AAA';
is $elem<@*[name()='x:aaa']>, 'AAA';
is $elem<attribute::x:aaa>, 'AAA';
is $elem.findvalue('name(@*)'), 'foo';
is-deeply %atts.keys.sort, ('foo', "x:aaa", "x:bbb", "x:ccc"), 'attribute keys';
$elem.appendTextChild('p', "some text");
is-deeply $elem.keys.sort, ('@foo', "@x:aaa", "@x:bbb", "@x:ccc", "p"), 'element keys';
is-deeply $elem.Hash.keys.sort, ('@foo', "@x:aaa", "@x:bbb", "@x:ccc", "p"), 'element keys';
is $elem.Hash<@foo>, 'bar';
is $elem<p>, "<p>some text</p>";
is $elem<p>[0].tag, 'p';

lives-ok  {$elem<@x:aaa> = 'BBB' };
is $elem<@x:aaa>,'BBB';

my $prefix = $elem.raw.genNsPrefix;
is $prefix, '_ns0', 'first generated NS prefix';
$elem.requireNamespace('http://ns2');
$prefix = $elem.raw.genNsPrefix;
is $prefix, '_ns1', 'second generated NS prefix';

my $elem-xpath-ctxt = $elem.xpath-context;
$elem.setNamespace('http://ns', 'x', :!activate);
is $elem<@x:aaa>, 'BBB', 'registered namespace';
lives-ok {$attr = ($elem<@x:aaa>:delete)[0]}, 'delete via ns';

is($elem.Str, '<foo xmlns:x="http://ns" xmlns:_ns0="http://ns2" foo="bar" x:bbb="BBB" x:ccc="CCC"><p>some text</p></foo>', 'NS Elem after NS proxy deletion');

ok $elem.isSupported('HTML');
nok $elem.isSupported('LOLCODE');



