use Test;
use LibXML;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Native;

plan 15;

my $string = "<a>    <b/> </a>";
my $tstr= "<a><b/></a>";
my $sDoc   = '<C/><D/>';
my $sChunk = '<A/><B/>';

my LibXML $parser .= new;
$parser.keep-blanks = False;
$parser.config.skip-xml-declaration = True;
my LibXML::Document $doc = $parser.parse: :$string;
is $doc.Str,  $tstr;
is-deeply $doc.doc, $doc, 'doc self-root';

my LibXML::DocumentFragment $frag = $parser.parse-balanced: :chunk( $sDoc);
my LibXML::DocumentFragment $chk = $parser.parse-balanced: :chunk( $sChunk);

lives-ok {$frag.appendChild( $chk )}, 'appendChild lives';

is( $frag.Str, '<C/><D/><A/><B/>', 'No segfault parsing string "<C/><D/><A/><B/>"');

# create a document from scratch
$doc .= new;
my LibXML::Element:D $root .= new: :name<Test>;
$doc.documentElement = $root;
my LibXML::Element:D $root2 = $doc.documentElement;
todo "maintain object cache";
ok $root === $root2, 'See issue #2';
is $root, '<Test/>', 'Root Element';
is $doc, '<Test/>', 'Document';

# attribute basics
my $elem = $doc.createElement('foo');
my $attr = $doc.createAttribute('attr', 'e & f');
$elem.setAttributeNode($attr);
is $attr, ' attr="e &amp; f"', 'attr.Str';
is $elem.node.properties, $attr, 'elem properties linkage';
is $attr.node.parent.properties, $attr, 'attribute parent linkage';
my $att2 = $elem.getAttributeNode('attr');
is $att2.Str, ' attr="e &amp; f"', 'att2.Str';
ok $attr.isSameNode($att2);
is($elem, '<foo attr="e &amp; f"/>', 'Elem with attribute added');
$elem.removeAttribute('attr');
$att2 = $elem.getAttributeNode('attr');
nok $att2.defined, 'getAttributeNode after removal';
is($elem.Str, '<foo/>', 'Elem with attribute removed');
