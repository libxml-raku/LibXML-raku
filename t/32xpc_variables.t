use v6;
use Test;
plan 35;

use LibXML;
use LibXML::XPath::Context;
use LibXML::Enums;

# silence tests
my $errors;
LibXML::XPath::Context.SetGenericErrorFunc(-> $ctx, $fmt, |c { $errors++ });

my $doc = LibXML.parse: :string(q:to<XML>);
<foo><bar a="b">Bla</bar><bar/></foo>
XML

my %variables = (
	'a' => 2,
	'b' => "b",
	);

sub get_variable($name, $uri ) {
    %variables{$name};
}

# $c: nodelist
%variables<c> = LibXML::XPath::Context.new(:$doc).findnodes('//bar');
isa-ok(%variables<c>, 'LibXML::Node::Set', ' TODO : Add test name');
is(%variables<c>.size(), 2, ' TODO : Add test name');
is(%variables<c>[1].nodeName, 'bar', ' TODO : Add test name');

# $d: a single element node
%variables<d> = LibXML::XPath::Context.new(:$doc).findnodes('/*').pop;
is(%variables<d>.nodeName(), 'foo', ' TODO : Add test name');

# $e: a single text node
%variables<e> = LibXML::XPath::Context.new(:$doc).findnodes('//text()');
is(%variables<e>[0].data(), 'Bla', ' TODO : Add test name');

# $f: a single attribute node
%variables<f> = LibXML::XPath::Context.new(:$doc).findnodes('//@*').pop;
is(%variables<f>.nodeName(), 'a', ' TODO : Add test name');
is(%variables<f>.value(), 'b', ' TODO : Add test name');

# $f: a single document node
%variables<g> = LibXML::XPath::Context.new(:$doc).findnodes('/').pop;
is(%variables<g>.nodeType(), +XML_DOCUMENT_NODE, ' TODO : Add test name');

# test registerVarLookupFunc() and getVarLookupData()
my $xc = LibXML::XPath::Context.new(:$doc);

##ok(!defined($xc.getVarLookupData), ' TODO : Add test name');
$xc.registerVarLookupFunc(&get_variable);
skip('varLookupData - do we need this?', 5);
##ok(defined($xc.getVarLookupData), ' TODO : Add test name');
##my $h1=$xc.getVarLookupData;
##my $h2=\%variables;
##ok("$h1" eq "$h2", ' TODO : Add test name' );
##ok($h1 eq $xc.getVarLookupData, ' TODO : Add test name');
##is-deeply(\&get_variable, $xc.getVarLookupFunc, ' TODO : Add test name');

# test values returned by XPath queries
is($xc.find('$a'), 2, ' TODO : Add test name');
is($xc.find('$b'), "b", ' TODO : Add test name');
is($xc.findnodes('//@a[.=$b]').size(), 1, ' TODO : Add test name');
is($xc.findnodes('//@a[.=$b]').size(), 1, ' TODO : Add test name');

is($xc.findnodes('$c').size(), 2, ' TODO : Add test name');
is($xc.findnodes('$c').size(), 2, ' TODO : Add test name');
ok($xc.findnodes('$c[1]').pop.isSameNode(%variables<c>[0]), ' TODO : Add test name');
is($xc.findnodes('$c[@a="b"]').size(), 1, ' TODO : Add test name');
is($xc.findnodes('$d').size(), 1, ' TODO : Add test name');
is($xc.findnodes('$d/*').size(), 2, ' TODO : Add test name');
ok($xc.findnodes('$d').pop.isSameNode(%variables<d>), ' TODO : Add test name');
ok($xc.findvalue('$e') eq 'Bla', ' TODO : Add test name');
ok($xc.findnodes('$e').pop.isSameNode(%variables<e>[0]), ' TODO : Add test name');
is($xc.findnodes('$c[@*=$f]').size(), 1, ' TODO : Add test name');
is($xc.findvalue('$f'), 'b', ' TODO : Add test name');
is($xc.findnodes('$f').pop.nodeName, 'a', ' TODO : Add test name');
ok($xc.findnodes('$f').pop.isSameNode(%variables<f>), ' TODO : Add test name');
ok($xc.findnodes('$g').pop.isSameNode(%variables<g>), ' TODO : Add test name');

# unregiser variable lookup
$xc.unregisterVarLookupFunc();
dies-ok { $xc.find('$a') }, ' TODO : Add test name';
ok(!defined($xc.getVarLookupFunc()), ' TODO : Add test name');

skip('varLookupData - do we need this?', 2);
##my $foo='foo';
##$xc.registerVarLookupFunc(sub {},$foo);
##ok($xc.getVarLookupData eq 'foo', ' TODO : Add test name');
##$foo=undef;
##ok($xc.getVarLookupData eq 'foo', ' TODO : Add test name');

