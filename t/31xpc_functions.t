use Test;
plan 31;

use LibXML;
use LibXML::Document;
use LibXML::XPath::Context;

my $doc = LibXML.parse: :string(q:to<XML>);
<foo><bar a="b">Bla</bar><bar/></foo>
XML
# TEST
ok($doc, ' TODO : Add test name');

my $xc = LibXML::XPath::Context.new(:$doc);
$xc.registerNs('foo','urn:foo');

# low level test
use LibXML::Native;
$xc.registerFunctionNS('copy','urn:foo', -> $v { $v }  );

# copy string, real, integer, nodelist
# TEST
is($xc.findvalue('foo:copy("bar")'), 'bar', ' TODO : Add test name');
# TEST

is-approx($xc.findvalue('foo:copy(3.14)'), 3.14, ' TODO : Add test name');
# TEST

is($xc.findvalue('foo:copy(7)'), 7, ' TODO : Add test name');
# TEST

is($xc.find('foo:copy(//*)').size(), 3, ' TODO : Add test name');
my ($foo)=$xc.findnodes('(//*)[2]');
# TEST

ok($xc.findnodes('foo:copy(//*)[2]').pop.isSameNode($foo), ' TODO : Add test name');

# too many arguments

dies-ok { $xc.findvalue('foo:copy(1,xyz)') }, ' TODO : Add test name';

# without a namespace
$xc.registerFunction('dummy', sub { 'DUMMY' });
# TEST

is($xc.findvalue('dummy()'), 'DUMMY', ' TODO : Add test name');

# unregister it
$xc.unregisterFunction('dummy');
dies-ok { $xc.findvalue('dummy()') }, ' TODO : Add test name';

# register by name
sub dummy2 { 'DUMMY2' };
$xc.registerFunction('dummy2', &dummy2);
# TEST

is($xc.findvalue('dummy2()'), 'DUMMY2', ' TODO : Add test name');

# unregister
$xc.unregisterFunction('dummy2');
dies-ok { $xc.findvalue('dummy2()') }, ' TODO : Add test name';


# a mix of different arguments types
$xc.registerFunction(
    'join',
    -> $sep, *@nodes {
        join($sep, flat @nodes.map: { .list.map: { .isa(LibXML::Node) ?? .nodeName !! $_ } } );
    }
    );

# TEST

is($xc.findvalue('join("","a","b","c")'), 'abc', ' TODO : Add test name');
# TEST

is($xc.findvalue('join("-","a",/foo,//*)'), 'a-foo-foo-bar-bar', ' TODO : Add test name');
# TEST

is($xc.findvalue('join("-",foo:copy(//*))'), 'foo-bar-bar', ' TODO : Add test name');

# unregister foo:copy
$xc.unregisterFunctionNS('copy','urn:foo');
dies-ok { $xc.findvalue('foo:copy("bar")') }, ' TODO : Add test name';

# test context reentrance
$xc.registerFunction('test-lock1', -> $a? { $xc.find('string(//node())'); });
$xc.registerFunction('test-lock2', -> $a? { $xc.findnodes('//bar'); });
# TEST

is($xc.find('test-lock1()'), $xc.find('string(//node())'), ' TODO : Add test name');
# TEST

ok($xc.find('count(//bar)=2'), ' TODO : Add test name');
# TEST

ok($xc.find('count(test-lock2())=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc.find('count(test-lock2()|//bar)=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc.findnodes('test-lock2()[2]').pop().isSameNode($xc.findnodes('//bar[2]')[0]), ' TODO : Add test name');

$xc.registerFunction('test-lock3', sub { $xc.findnodes('test-lock2(//bar)') });
# TEST

ok($xc.find('count(test-lock2())=count(test-lock3())'), ' TODO : Add test name');
# TEST

ok($xc.find('count(test-lock3())=count(//bar)'), ' TODO : Add test name');
# TEST

ok($xc.find('count(test-lock3()|//bar)=count(//bar)'), ' TODO : Add test name');

# function creating new nodes
$xc.registerFunction('new-foo',
		      sub {
			return $doc.createElement('foo');
		      });
# TEST

is($xc.findnodes('new-foo()').pop().nodeName, 'foo', ' TODO : Add test name');
my ($test_node) = $xc.findnodes('new-foo()');

$xc.registerFunction('new-chunk',
		      sub {
			    LibXML.parse(:string('<x><y><a/><a/></y><y><a/></y></x>')).find('//a');
		      });
# TEST

is($xc.findnodes('new-chunk()').size(), 3, ' TODO : Add test name');

my ($x)=$xc.findnodes('new-chunk()/parent::*');
# TEST

is($x.nodeName(), 'y', ' TODO : Add test name');
# TEST
is($xc.findvalue('name(new-chunk()/parent::*)'), 'y', ' TODO : Add test name');
# TEST

ok($xc.findvalue('count(new-chunk()/parent::*)=2'), ' TODO : Add test name');

my LibXML::Document $largedoc .= parse: :string('<a>'~ ('<b/>' x 300) ~ '</a>');
$xc .= new: :doc($largedoc);
$xc.setContextNode($largedoc.documentElement);
$xc.registerFunction(
    'pass1', -> {
	$largedoc.findnodes('(//*)')
    }
);
$xc.registerFunction('pass2', -> $v { $v } );

$xc.registerVarLookupFunc(
    -> $name, $uri {
        $largedoc.findnodes('(//*)')
    }
);

# TEST

is($xc.find('$a[name()="b"]').size(), 300, ' TODO : Add test name');
my $pass1=$xc.findnodes('pass1()');
# TEST

is($pass1.size, 301, ' TODO : Add test name');
# TEST

is($xc.find('pass2(//*)').size(), 301, ' TODO : Add test name');
