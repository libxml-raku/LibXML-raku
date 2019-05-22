use Test;
plan 82;

use LibXML;
use LibXML::XPathContext;
use LibXML::XPathExpression;

my $doc = LibXML.new.parse: :string(q:to<XML>);
<foo><bar a="b"></bar></foo>
XML

# test findnodes() in list context
my $xpath = '/*';
# TEST:$exp=2;
for ($xpath, LibXML::XPathExpression.parse($xpath)) -> $exp {
    my @nodes = LibXML::XPathContext.new(:$doc).findnodes($exp).list;
  # TEST*$exp
  ok(@nodes == 1, ' TODO : Add test name');
  # TEST*$exp
  ok(@nodes[0].nodeName eq 'foo', ' TODO : Add test name');
  # TEST*$exp
  is(
      (LibXML::XPathContext.new( node => @nodes[0]).findnodes('bar'))[0].nodeName(),
      'bar',
      ' TODO : Add test list',
  );
}

# test findnodes() in scalar context
# TEST:$exp=2;
for ($xpath, LibXML::XPathExpression.parse($xpath)) -> $exp {
  my $nl = LibXML::XPathContext.new(:$doc).findnodes($exp);
  # TEST*$exp
  ok($nl.pop.nodeName eq 'foo', ' TODO : Add test name');
  # TEST*$exp
  ok(!defined($nl.pop), ' TODO : Add test name');
}


# test findvalue()
# TEST
is(LibXML::XPathContext.new(:$doc).findvalue('1+1'), 2, ' TODO : Add test name');
# TEST

is(LibXML::XPathContext.new(:$doc).findvalue(LibXML::XPathExpression.parse('1+1')), 2, ' TODO : Add test name');
# TEST

is-deeply(LibXML::XPathContext.new(:$doc).findvalue('1=2'), False, ' TODO : Add test name');
# TEST

is-deeply(LibXML::XPathContext.new(:$doc).findvalue(LibXML::XPathExpression.parse('1=2')), False, ' TODO : Add test name');

# test find()
# TEST
ok(LibXML::XPathContext.new(:$doc).find('/foo/bar').pop.nodeName eq 'bar', ' TODO : Add test name');
# TEST

ok(LibXML::XPathContext.new(:$doc).find(LibXML::XPathExpression.parse('/foo/bar')).pop.nodeName eq 'bar', ' TODO : Add test name');

# TEST

is(LibXML::XPathContext.new(:$doc).find('1*3'), 3, ' TODO : Add test name');
# TEST

is(LibXML::XPathContext.new(:$doc).find('1=1'), True, ' TODO : Add test name');

my $doc1 = LibXML.new.parse: :string(q:to<XML>);
<foo xmlns="http://example.com/foobar"><bar a="b"></bar></foo>
XML

# test registerNs()
my $compiled = LibXML::XPathExpression.parse('/xxx:foo');
my $xc = LibXML::XPathContext.new: :doc($doc1);
$xc.registerNs('xxx', 'http://example.com/foobar');
# TEST

ok($xc.findnodes('/xxx:foo').pop.nodeName eq 'foo', ' TODO : Add test name');
# TEST

ok($xc.findnodes($compiled).pop.nodeName eq 'foo', ' TODO : Add test name');
# TEST

skip("todo port remaining tests", 62);
=begin TODO

ok($xc.lookupNs('xxx') eq 'http://example.com/foobar', ' TODO : Add test name');
# TEST

ok($xc.exists('//xxx:bar/@a'), ' TODO : Add test name');
# TEST

is($xc.exists('//xxx:bar/@b'),0, ' TODO : Add test name');
# TEST

ok($xc.exists('xxx:bar',$doc1.getDocumentElement), ' TODO : Add test name');

# test unregisterNs()
$xc.unregisterNs('xxx');
eval { $xc.findnodes('/xxx:foo') };
# TEST

ok($@, ' TODO : Add test name');
# TEST

ok(!defined($xc.lookupNs('xxx')), ' TODO : Add test name');

eval { $xc.findnodes($compiled) };
# TEST

ok($@, ' TODO : Add test name');
# TEST

ok(!defined($xc.lookupNs('xxx')), ' TODO : Add test name');

# test getContextNode and setContextNode
# TEST
ok($xc.getContextNode.isSameNode($doc1), ' TODO : Add test name');
$xc.setContextNode($doc1.getDocumentElement);
# TEST

ok($xc.getContextNode.isSameNode($doc1.getDocumentElement), ' TODO : Add test name');
# TEST

ok($xc.findnodes('.').pop.isSameNode($doc1.getDocumentElement), ' TODO : Add test name');

# test xpath context preserves the document
my $xc2 = LibXML::XPathContext.new(
	  LibXML.new.parse_string(<<'XML'));
<foo/>
XML
# TEST

ok($xc2.findnodes('*').pop.nodeName eq 'foo', ' TODO : Add test name');

# test xpath context preserves context node
my $doc2 = LibXML.new.parse_string(<<'XML');
<foo><bar/></foo>
XML
my $xc3 = LibXML::XPathContext.new($doc2.getDocumentElement);
$xc3.find('/');
# TEST

ok($xc3.getContextNode.toString() eq '<foo><bar/></foo>', ' TODO : Add test name');

# check starting with empty context
my $xc4 = LibXML::XPathContext.new();
# TEST

ok(!defined($xc4.getContextNode), ' TODO : Add test name');
eval { $xc4.find('/') };
# TEST

ok($@, ' TODO : Add test name');
my $cn=$doc2.getDocumentElement;
$xc4.setContextNode($cn);
# TEST

ok($xc4.find('/'), ' TODO : Add test name');
# TEST

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');
$cn=undef;
# TEST

ok($xc4.getContextNode, ' TODO : Add test name');
# TEST

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

# check temporarily changed context node
my ($bar)=$xc4.findnodes('foo/bar',$doc2);
# TEST

ok($bar.nodeName eq 'bar', ' TODO : Add test name');
# TEST

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

# TEST

ok($xc4.findnodes('parent::*',$bar).pop.nodeName eq 'foo', ' TODO : Add test name');
# TEST

ok($xc4.getContextNode.isSameNode($doc2.getDocumentElement), ' TODO : Add test name');

# testcase for segfault found by Steve Hay
my $xc5 = LibXML::XPathContext.new();
$xc5.registerNs('pfx', 'http://www.foo.com');
$doc = LibXML.new.parse_string('<foo xmlns="http://www.foo.com" />');
$xc5.setContextNode($doc);
$xc5.findnodes('/');
$xc5.setContextNode(undef);
$xc5.getContextNode();
$xc5.setContextNode($doc);
$xc5.findnodes('/');
# TEST

ok(1, ' TODO : Add test name');

# check setting context position and size
# TEST
ok($xc4.getContextPosition() == -1, ' TODO : Add test name');
# TEST

ok($xc4.getContextSize() == -1, ' TODO : Add test name');
eval { $xc4.setContextPosition(4); };
# TEST

ok($@, ' TODO : Add test name');
eval { $xc4.setContextPosition(-4); };
# TEST

ok($@, ' TODO : Add test name');
eval { $xc4.setContextSize(-4); };
# TEST

ok($@, ' TODO : Add test name');
eval { $xc4.findvalue('position()') };
# TEST

ok($@, ' TODO : Add test name');
eval { $xc4.findvalue('last()') };
# TEST

ok($@, ' TODO : Add test name');

$xc4.setContextSize(0);
# TEST

ok($xc4.getContextSize() == 0, ' TODO : Add test name');
# TEST

ok($xc4.getContextPosition() == 0, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('position()')==0, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('last()')==0, ' TODO : Add test name');

$xc4.setContextSize(4);
# TEST

ok($xc4.getContextSize() == 4, ' TODO : Add test name');
# TEST

ok($xc4.getContextPosition() == 1, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('last()')==4, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('position()')==1, ' TODO : Add test name');
eval { $xc4.setContextPosition(5); };
# TEST

ok($@, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('position()')==1, ' TODO : Add test name');
# TEST

ok($xc4.getContextSize() == 4, ' TODO : Add test name');
$xc4.setContextPosition(4);
# TEST

ok($xc4.findvalue('position()')==4, ' TODO : Add test name');
# TEST

ok($xc4.findvalue('position()=last()'), ' TODO : Add test name');

$xc4.setContextSize(-1);
# TEST

ok($xc4.getContextPosition() == -1, ' TODO : Add test name');
# TEST

ok($xc4.getContextSize() == -1, ' TODO : Add test name');
eval { $xc4.findvalue('position()') };
# TEST

ok($@, ' TODO : Add test name');
eval { $xc4.findvalue('last()') };
# TEST

ok($@, ' TODO : Add test name');

{
    my $d = LibXML.new().parse_string(q~<x:a xmlns:x="http://x.com" xmlns:y="http://x1.com"><x1:a xmlns:x1="http://x1.com"/></x:a>~);
    {
        my $x = LibXML::XPathContext.new;

        # use the document's declaration
        # TEST
        ok( $x.findvalue('count(/x:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );

        $x.registerNs('x', 'http://x1.com');
        # x now maps to http://x1.com, so it won't match the top-level element
        # TEST
        ok( $x.findvalue('count(/x:a)',$d.documentElement)==0, ' TODO : Add test name' );

        $x.registerNs('x1', 'http://x.com');
        # x1 now maps to http://x.com
        # x1:a will match the first element
        # TEST
        ok( $x.findvalue('count(/x1:a)',$d.documentElement)==1, ' TODO : Add test name' );
        # but not the second
        # TEST
        ok( $x.findvalue('count(/x1:a/x1:a)',$d.documentElement)==0, ' TODO : Add test name' );
        # this will work, though
        # TEST
        ok( $x.findvalue('count(/x1:a/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        # the same using y for http://x1.com
        # TEST
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.registerNs('y', 'http://x.com');
        # y prefix remapped
        # TEST
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==0, ' TODO : Add test name' );
        # TEST
        ok( $x.findvalue('count(/y:a/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.registerNs('y', 'http://x1.com');
        # y prefix remapped back
        # TEST
        ok( $x.findvalue('count(/x1:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.unregisterNs('x');
        # TEST
        ok( $x.findvalue('count(/x:a)',$d.documentElement)==1, ' TODO : Add test name' );
        $x.unregisterNs('y');
        # TEST
        ok( $x.findvalue('count(/x:a/y:a)',$d.documentElement)==1, ' TODO : Add test name' );
    }
}

SKIP:
{
    # 37332
    if (LibXML::LIBXML_VERSION() < 20617) {
        skip(
            'xpath does not work on nodes without a document in libxml2 < 2.6.17',
            3
        );
    }
    my $frag = LibXML::DocumentFragment.new;
    my $foo = LibXML::Element.new('foo');
    my $xpc = LibXML::XPathContext.new;
    $frag.appendChild($foo);
    $foo.appendTextChild('bar', 'quux');
    {
        my @n = $xpc.findnodes('./foo', $frag);
        # TEST
        ok ( @n == 1, ' TODO : Add test name' );
    }
    {
        my @n = $xpc.findnodes('./foo/bar', $frag);
        # TEST
        ok ( @n == 1, ' TODO : Add test name' );
    }
    {
        my @n = $xpc.findnodes('./bar', $foo);
        # TEST
        ok ( @n == 1, ' TODO : Add test name' );
    }
}
=end TODO
                                   
