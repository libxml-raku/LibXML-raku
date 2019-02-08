use Test;
use LibXML;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Native;

plan 6;

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

$frag.appendChild( $chk );

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
