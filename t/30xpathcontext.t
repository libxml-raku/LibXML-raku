use v6;
use Test;
plan 88;

use LibXML;
use LibXML::XPath::Context;
use LibXML::XPath::Expression;

my $errors;

my $doc = LibXML.parse: :string(q:to<XML>);
<foo><bar a="b"></bar><baz/></foo>
XML

# test findnodes() in list context
my $xpath = '/*';
my $xpath2 = '/*/*';
for ($xpath, LibXML::XPath::Expression.parse($xpath)) -> $exp {
    my @nodes = LibXML::XPath::Context.new(:$doc).findnodes($exp);
    ok(@nodes == 1, ' TODO : Add test name');
    ok(@nodes[0].nodeName eq 'foo', ' TODO : Add test name');
    is(
      (LibXML::XPath::Context.new( node => @nodes[0]).findnodes('bar'))[0].nodeName(),
      'bar',
      ' TODO : Add test list',
  );
}

# test findnodes() in scalar context
for ($xpath, LibXML::XPath::Expression.parse($xpath)) -> $exp {
  my $nl = LibXML::XPath::Context.new(:$doc).findnodes($exp);
  ok($nl.pop.nodeName eq 'foo', ' TODO : Add test name');
  ok(!defined($nl.pop), ' TODO : Add test name');
}

# test  first(), last()
for ($xpath~'/*', LibXML::XPath::Expression.parse($xpath~'/*')) -> $exp {
  my $ctx = LibXML::XPath::Context.new(:$doc);
  is $ctx.first($exp).nodeName, 'bar';
  is $ctx.last($exp).nodeName, 'baz';
}

# test findvalue()
is(LibXML::XPath::Context.new(:$doc).findvalue('1+1'), 2, ' TODO : Add test name');

is(LibXML::XPath::Context.new(:$doc).findvalue(LibXML::XPath::Expression.parse('1+1')), 2, ' TODO : Add test name');

is-deeply(LibXML::XPath::Context.new(:$doc).findvalue('1=2'), False, ' TODO : Add test name');

is-deeply(LibXML::XPath::Context.new(:$doc).findvalue(LibXML::XPath::Expression.parse('1=2')), False, ' TODO : Add test name');

# test find()
ok(LibXML::XPath::Context.new(:$doc).find('/foo/bar').pop.nodeName eq 'bar', ' TODO : Add test name');

ok(LibXML::XPath::Context.new(:$doc).find(LibXML::XPath::Expression.parse('/foo/bar')).pop.nodeName eq 'bar', ' TODO : Add test name');


is(LibXML::XPath::Context.new(:$doc).find('1*3'), 3, ' TODO : Add test name');
is(LibXML::XPath::Context.new(:$doc).find('1=1'), True, ' TODO : Add test name');

my $doc1 = LibXML.parse: :string(q:to<XML>);
<foo xmlns="http://example.com/foobar"><bar a="b"></bar></foo>
XML

# test registerNs()
my $compiled = LibXML::XPath::Expression.parse('/xxx:foo');
my $xc = LibXML::XPath::Context.new: :doc($doc1);
$xc.SetGenericErrorFunc(-> $ctx, $fmt, |c { $errors++; });
$xc.registerNs('xxx', 'http://example.com/foobar');

ok($xc.findnodes('/xxx:foo').pop.nodeName eq 'foo', ' TODO : Add test name');

ok($xc.findnodes($compiled).pop.nodeName eq 'foo', ' TODO : Add test name');

is($xc.lookupNs('xxx'), 'http://example.com/foobar', ' TODO : Add test name');

ok($xc.exists('//xxx:bar/@a'), ' TODO : Add test name');

is($xc.exists('//xxx:bar/@b'), False, ' TODO : Add test name');

ok($xc.exists('xxx:bar', $doc1.getDocumentElement), ' TODO : Add test name');

# test unregisterNs()
$xc.unregisterNs('xxx');
dies-ok { $xc.findnodes('/xxx:foo') }, 'Find unregistered NS';

ok(!defined($xc.lookupNs('xxx')), 'Lookup unregistered NS');

dies-ok { $xc.findnodes($compiled) }, ' TODO : Add test name';

ok(!defined($xc.lookupNs('xxx')), ' TODO : Add test name');

# test getContextNode and setContextNode
ok($xc.getContextNode.isSameNode($doc1), ' TODO : Add test name');

$xc.setContextNode($doc1.getDocumentElement);

ok($xc.getContextNode.isSameNode($doc1.getDocumentElement), 'Context node is document element');

ok($xc.findnodes('.').pop.isSameNode($doc1.getDocumentElement), 'First node is document element');

# test xpath context preserves the document
$doc = LibXML.parse: :string(q:to<XML>);
<foo/>
XML
my $xc2 = LibXML::XPath::Context.new( :$doc );
is($xc2.findnodes('//*').pop.nodeName, 'foo', 'First node is root node');

# test xpath context preserves context node
my $doc2 = LibXML.parse: :string(q:to<XML>);
<foo><bar/></foo>
XML
my $xc3 = LibXML::XPath::Context.new(node => $doc2.getDocumentElement);
$xc3.find('/');

is($xc3.getContextNode.Str(), '<foo><bar/></foo>', 'context is root node');

# check starting with empty context
my $xc4;
lives-ok { $xc4 = LibXML::XPath::Context.new() }, 'new empty context';
ok !defined($xc4.getContextNode), 'getContextNode when empty';
dies-ok { $xc4.find('/') }, 'find of empty dies';
my $cn = $doc2.getDocumentElement;
$xc4.setContextNode($cn);
ok($xc4.find('/'), ' TODO : Add test name');

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');
$cn = Nil;

ok($xc4.getContextNode, ' TODO : Add test name');

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

# check temporarily changed context node
my ($bar)=$xc4.findnodes('foo/bar',$doc2);

is($bar.nodeName, 'bar', ' TODO : Add test name');

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

is($xc4.findnodes('parent::*',$bar).pop.nodeName, 'foo', ' TODO : Add test name');

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

# testcase for segfault found by Steve Hay

my $xc5 = LibXML::XPath::Context.new();
$xc5.registerNs('pfx', 'http://www.foo.com');
$doc = LibXML.parse: :string('<foo xmlns="http://www.foo.com" />');
$xc5.setContextNode($doc);
$xc5.findnodes('/');
dies-ok {$xc5.setContextNode($doc2)}, 'changing document is not supported';
$xc5.getContextNode();
$xc5.setContextNode($doc);
$xc5.findnodes('/');

pass(' TODO : Add test name');

# check setting context position and size
ok($xc4.getContextPosition() == -1, ' TODO : Add test name');

dies-ok { $xc4.setContextPosition(4); },' TODO : Add test name';
dies-ok { $xc4.setContextPosition(-4); }, ' TODO : Add test name';
dies-ok { $xc4.setContextSize(-4); }, ' TODO : Add test name';
dies-ok { $xc4.findvalue('position()') }, ' TODO : Add test name';
dies-ok { $xc4.findvalue('last()') };

is($xc4.getContextSize(), -1, ' TODO : Add test name');

$xc4.setContextSize(0);

ok($xc4.getContextSize() == 0, ' TODO : Add test name');

is($xc4.getContextPosition(), 0, ' TODO : Add test name');

is($xc4.findvalue('position()'), 0, ' TODO : Add test name');

is($xc4.findvalue('last()'), 0, ' TODO : Add test name');

$xc4.setContextSize(4);

is($xc4.getContextSize(), 4, ' TODO : Add test name');

is($xc4.getContextPosition(), 1, ' TODO : Add test name');

is($xc4.findvalue('last()'), 4, ' TODO : Add test name');

is($xc4.findvalue('position()'), 1, ' TODO : Add test name');
dies-ok { $xc4.setContextPosition(5); }, ' TODO : Add test name';

is($xc4.findvalue('position()'), 1, ' TODO : Add test name');

is($xc4.getContextSize(), 4, ' TODO : Add test name');
$xc4.setContextPosition(4);

is($xc4.findvalue('position()'), 4, ' TODO : Add test name');

ok($xc4.findvalue('position()=last()'), ' TODO : Add test name');

$xc4.setContextSize(-1);

is($xc4.getContextPosition(), -1, ' TODO : Add test name');

is($xc4.getContextSize(), -1, ' TODO : Add test name');
dies-ok { $xc4.findvalue('position()') }, ' TODO : Add test name';
dies-ok { $xc4.findvalue('last()') }, ' TODO : Add test name';

{
    my $d = LibXML.new().parse: :string(q~<x:a xmlns:x="http://x.com" xmlns:y="http://x1.com"><x1:a xmlns:x1="http://x1.com"/></x:a>~);
    {
        my $x = LibXML::XPath::Context.new;

        # use the document's declaration
        is( $x.findvalue('count(/x:a/y:a)', $d.documentElement), 1, ' TODO : Add test name' );

        $x.registerNs('x', 'http://x1.com');
        # x now maps to http://x1.com, so it won't match the top-level element

        is( $x.findvalue('count(/x:a)', $d.documentElement), 0, ' TODO : Add test name' );

        $x.registerNs('x1', 'http://x.com');
        # x1 now maps to http://x.com
        # x1:a will match the first element
        ok( $x.findvalue('count(/x1:a)',$d.documentElement)==1, ' TODO : Add test name' );
        # but not the second
        ok( $x.findvalue('count(/x1:a/x1:a)',$d.documentElement)==0, ' TODO : Add test name' );
        # this will work, though
        ok( $x.findvalue('count(/x1:a/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        # the same using y for http://x1.com
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.registerNs('y', 'http://x.com');
        # y prefix remapped
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==0, ' TODO : Add test name' );
        ok( $x.findvalue('count(/y:a/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.registerNs('y', 'http://x1.com');
        # y prefix remapped back
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.unregisterNs('x');
        ok( $x.findvalue('count(/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.unregisterNs('y');
        ok( $x.findvalue('count(/x:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
    }
}

{
    my $frag = LibXML::DocumentFragment.new;
    my $foo = LibXML::Element.new('foo');
    my $xpc = LibXML::XPath::Context.new;
    $frag.appendChild($foo);
    $foo.appendTextChild('bar', 'quux');
    {
        my @n = $xpc.findnodes('./foo', $frag);
        ok ( @n == 1, ' TODO : Add test name' );
    }
    {
        my @n = $xpc.findnodes('./foo/bar', $frag);
        ok ( @n == 1, ' TODO : Add test name' );
    }
    {
        my @n = $xpc.findnodes('./bar', $foo);
        ok ( @n == 1, ' TODO : Add test name' );
    }
}
                                   
