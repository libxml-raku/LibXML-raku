use v6;
use Test;
plan 13;

use LibXML;
use LibXML::Document;
use LibXML::XPath::Context;

my LibXML::Document:D $doc .= parse: :string(q:to<XML>);
<foo><bar a="b">Bla</bar><bar/></foo>
XML

my $errors;

my LibXML::XPath::Context $xc .= new(:$doc);
$xc.SetStructuredErrorFunc(-> $fmt, |c { $errors++ });
$xc.registerNs('foo','urn:foo');
# low level test
subtest 'registerFunctionNS', {
    $xc.registerFunctionNS('copy','urn:foo', -> $v { $v }  );

    # copy string, real, integer, nodelist
    is $xc.findvalue('foo:copy("bar")'), 'bar';

    is-approx $xc.findvalue('foo:copy(3.14)'), 3.14;

    is $xc.findvalue('foo:copy(7)'), 7;

    is $xc.find('foo:copy(//*)').size(), 3;
    my ($foo) = $xc.findnodes('(//*)[2]');

    ok $xc.findnodes('foo:copy(//*)[2]').pop.isSameNode($foo);
}

# too many arguments

throws-like { $xc.findvalue('foo:copy(1,xyz)'); }, X::LibXML, :message(/"Too many positionals passed; expected 1 argument but got 2"/), 'too many arguments';

# without a namespace
$xc.registerFunction('dummy', sub { 'DUMMY' });

is $xc.findvalue('dummy()'), 'DUMMY', 'registerFunction (no NS)';

# unregister it
$xc.unregisterFunction('dummy');
dies-ok { $xc.findvalue('dummy()') }, 'unregisterFunction';

# register by name
sub dummy2 { 'DUMMY2' };
$xc.registerFunction('dummy2', &dummy2);

is $xc.findvalue('dummy2()'), 'DUMMY2', 'register by name';

# unregister
$xc.unregisterFunction('dummy2');
dies-ok { $xc.findvalue('dummy2()') }, 'unregisterFunction';

subtest 'mixed argument types', {
    $xc.registerFunction(
        'join',
        -> $sep, *@nodes {
            join($sep, flat @nodes.map: { .list.map: { .isa(LibXML::Node) ?? .nodeName !! $_ } } );
        }
    );

    is $xc.findvalue('join("","a","b","c")'), 'abc';

    is $xc.findvalue('join("-","a",/foo,//*)'), 'a-foo-foo-bar-bar';

    is $xc.findvalue('join("-",foo:copy(//*))'), 'foo-bar-bar';
}
# unregister foo:copy
$xc.unregisterFunctionNS('copy','urn:foo');
dies-ok { $xc.findvalue('foo:copy("bar")') }, 'unregisterFunctionNS()';

subtest 'context reentrance', {
    $xc.registerFunction('test-lock1', -> $a? { $xc.find('string(//node())'); });
    $xc.registerFunction('test-lock2', -> $a? { $xc.findnodes('//bar'); });

    is $xc.find('test-lock1()'), $xc.find('string(//node())');

    ok $xc.find('count(//bar)=2');

    ok $xc.find('count(test-lock2())=count(//bar)');

    ok $xc.find('count(test-lock2()|//bar)=count(//bar)');

    ok $xc.first('test-lock2()[2]').isSameNode($xc.first('//bar[2]'));

    $xc.registerFunction('test-lock3', sub { $xc.findnodes('test-lock2(//bar)') });

    ok $xc.find('count(test-lock2())=count(test-lock3())');

    ok $xc.find('count(test-lock3())=count(//bar)');

    ok $xc.find('count(test-lock3()|//bar)=count(//bar)');
}

subtest 'node injection', {
    $xc.registerFunction: 'new-foo', sub {
	return $doc.createElement('foo');
    };

    is $xc.findnodes('new-foo()').pop().nodeName, 'foo';
    my ($test_node) = $xc.findnodes('new-foo()');

    $xc.registerFunction: 'new-chunk', sub {
	LibXML.parse(:string('<x><y><a/><a/></y><y><a/></y></x>')).find('//a');
    };

    is $xc.findnodes('new-chunk()').size(), 3;

    my ($x) = $xc.findnodes('new-chunk()/parent::*');

    is $x.nodeName(), 'y';
    is $xc.findvalue('name(new-chunk()/parent::*)'), 'y';

    ok $xc.findvalue('count(new-chunk()/parent::*)=2');
}

subtest 'identity function', {
    my LibXML::Document $largedoc .= parse: :string('<a>'~ ('<b/>' x 300) ~ '</a>');
    $xc .= new: :doc($largedoc);
    $xc.setContextNode($largedoc.documentElement);
    $xc.registerFunction: 'pass1', -> {
	$largedoc.findnodes('(//*)')
    }

    $xc.registerFunction: 'pass2', -> $v { $v };

    $xc.registerVarLookupFunc: -> $name, $uri {
        $largedoc.findnodes('(//*)')
    }


    is $xc.find('$a[name()="b"]').size(), 300;
    my $pass1=$xc.findnodes('pass1()');

    is $pass1.size, 301;

    is $xc.find('pass2(//*)').size(), 301;
}

subtest 'callback errors', {
    $xc.registerFunction(
        'die',
        -> *@a {
            die 'goodbye!';
        }
    );
    throws-like {$xc.findvalue('die("a","b")');}, X::LibXML, :message("XPath error: goodbye!");

    $xc.recover = True;
    my $v;
    quietly lives-ok {$v = $xc.findvalue('die("a","b")');}, "recover exception";
    is-deeply $v, False, 'recovered exception result';
    is-deeply $xc.findvalue('2=1+1'), True, "post-recovery function call";
}

ok $errors, 'errors trapped';
