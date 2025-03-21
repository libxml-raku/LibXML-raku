use v6;
use Test;
plan 25;

use LibXML;
use LibXML::Config;
use LibXML::XPath::Context;
use LibXML::XPath::Expression;
use LibXML::Node::Set;

my $errors;

my $doc = LibXML.parse: :string(q:to<XML>);
<foo><bar a="b"></bar><baz/></foo>
XML

my $xpath = '/*';
my $xpath2 = '/*/*';
subtest 'findnodes() list', {
    for ($xpath, LibXML::XPath::Expression.parse($xpath)) -> $exp {
        my @nodes = $doc.create(LibXML::XPath::Context, :$doc).findnodes($exp);
        is +@nodes, 1;
        is @nodes.head.nodeName,'foo';
        is(
            $doc.create(LibXML::XPath::Context,  node => @nodes[0]).findnodes('bar').head.nodeName(),
            'bar');
    }
}

subtest 'findnodes() scalar', {
    for ($xpath, LibXML::XPath::Expression.parse($xpath)) -> $exp {
        my LibXML::Node::Set:D $nl = $doc.create(LibXML::XPath::Context, :$doc).findnodes($exp);
        ok $nl.pop.nodeName eq 'foo';
        ok !defined($nl.pop);
    }
}

subtest 'first(), last()', {
    for ($xpath2, LibXML::XPath::Expression.parse($xpath2)) -> $exp {
        my LibXML::XPath::Context $ctx = $doc.create(LibXML::XPath::Context, :$doc);
        is $ctx.first($exp).nodeName, 'bar';
        is $ctx.last($exp).nodeName, 'baz';
    }
}

subtest 'findvalue()', {
    is $doc.create(LibXML::XPath::Context, :$doc).findvalue('1+1'), 2;

    is $doc.create(LibXML::XPath::Context, :$doc).findvalue(LibXML::XPath::Expression.parse('1+1')), 2;

    is-deeply $doc.create(LibXML::XPath::Context, :$doc).findvalue('1=2'), False;

    is-deeply $doc.create(LibXML::XPath::Context, :$doc).findvalue(LibXML::XPath::Expression.parse('1=2')), False;
}

subtest 'new(:$raw)', {
    use LibXML::Raw;
    my xmlXPathContext $raw .= new;
    my $ctx = $doc.create(LibXML::XPath::Context, :$raw, :$doc);
    cmp-ok $raw, '===', $ctx.raw;
    is $ctx.first($xpath2).nodeName, 'bar';
}

subtest 'find()', {
    ok $doc.create(LibXML::XPath::Context, :$doc).find('/foo/bar').pop.nodeName eq 'bar';

    ok $doc.create(LibXML::XPath::Context, :$doc).find(LibXML::XPath::Expression.parse('/foo/bar')).pop.nodeName eq 'bar';

    is $doc.create(LibXML::XPath::Context, :$doc).find('1*3'), 3;
    is $doc.create(LibXML::XPath::Context, :$doc).find('1=1'), True;
}

my $doc1 = LibXML.parse: :string(q:to<XML>);
<foo xmlns="http://example.com/foobar"><bar a="b"></bar></foo>
XML

sub registerNs-tests($compiled, $xc) {
    ok $xc.findnodes('/xxx:foo').pop.nodeName eq 'foo';

    ok $xc.findnodes($compiled).pop.nodeName eq 'foo';

    is $xc.lookupNs('xxx'), 'http://example.com/foobar';

    ok $xc.exists('//xxx:bar/@a');

    is-deeply $xc.exists('//xxx:bar/@b'), False;

    ok $xc.exists('xxx:bar', $doc1.getDocumentElement);

    # test unregisterNs()
    $xc.unregisterNs('xxx');
    dies-ok { $xc.findnodes('/xxx:foo') }, 'Find unregistered NS';

    ok !defined($xc.lookupNs('xxx')), 'Lookup unregistered NS';

    dies-ok { $xc.findnodes($compiled) };

    ok !defined($xc.lookupNs('xxx'));

    # test getContextNode and setContextNode
    ok $xc.getContextNode.isSameNode($doc1);

    $xc.setContextNode($doc1.getDocumentElement);

    ok $xc.getContextNode.isSameNode($doc1.getDocumentElement), 'Context node is document element';

    ok $xc.findnodes('.').pop.isSameNode($doc1.getDocumentElement), 'First node is document element';
}


my LibXML::XPath::Expression $compiled .= parse('/xxx:foo');
my LibXML::XPath::Context $xc1 = $doc1.create: LibXML::XPath::Context, :doc($doc1);
$xc1.SetGenericErrorFunc(-> $ctx, $fmt, |c { $errors++; });
$xc1.registerNs('xxx', 'http://example.com/foobar');
subtest 'registerNs', { registerNs-tests($compiled, $xc1) };

# test :%ns constructor
my LibXML::XPath::Context $xc2 = $doc1.create: LibXML::XPath::Context, :doc($doc1), :ns{ xxx => 'http://example.com/foobar' };
subtest ':%ns constructor', { registerNs-tests($compiled, $xc2) };


# test xpath context preserves the document
$doc = LibXML.parse: :string(q:to<XML>);
<foo/>
XML
$xc2 = $doc.create( $xc2.WHAT, :$doc );
is $xc2.findnodes('//*').pop.nodeName, 'foo', 'First node is root node';

# test xpath context preserves context node
my $doc2 = LibXML.parse: :string(q:to<XML>);
<foo><bar/></foo>
XML
my LibXML::XPath::Context $xc3 = $doc2.create(LibXML::XPath::Context, node => $doc2.getDocumentElement);
$xc3.find('/');

is $xc3.getContextNode.Str(), '<foo><bar/></foo>', 'context is root node' ;

# check starting with empty context
my LibXML::XPath::Context $xc4;
lives-ok { $xc4 = $doc2.create($xc4) }, 'new empty context';
ok !defined($xc4.getContextNode), 'getContextNode when empty';
dies-ok { $xc4.find('/') }, 'find of empty dies';
my $cn = $doc2.getDocumentElement;
$xc4.setContextNode($cn);
ok $xc4.find('/');

ok $xc4.getContextNode.isSameNode($doc2.getDocumentElement);
$cn = Nil;

ok $xc4.getContextNode;

ok $xc4.getContextNode.isSameNode($doc2.getDocumentElement);

# check temporarily changed context node
my ($bar)=$xc4.findnodes('foo/bar',$doc2);

is $bar.nodeName, 'bar';

ok $xc4.getContextNode.isSameNode($doc2.getDocumentElement);

is $xc4.findnodes('parent::*',$bar).pop.nodeName, 'foo';

ok $xc4.getContextNode.isSameNode($doc2.getDocumentElement);

# testcase for segfault found by Steve Hay

my LibXML::XPath::Context $xc5 = $doc2.create(LibXML::XPath::Context);
$xc5.registerNs('pfx', 'http://www.foo.com');
$doc = LibXML.parse: :string('<foo xmlns="http://www.foo.com" />');
$xc5.setContextNode($doc);
$xc5.findnodes('/');
dies-ok {$xc5.setContextNode($doc2)}, 'changing document is not supported';
$xc5.getContextNode();
$xc5.setContextNode($doc);
$xc5.findnodes('/');

subtest 'setting context position and size', {
    dies-ok { $xc4.setContextPosition(4); };
    dies-ok { $xc4.setContextPosition(-4); };
    dies-ok { $xc4.setContextSize(-4); };

    $xc4.setContextSize(0);

    ok $xc4.getContextSize() == 0;

    is $xc4.getContextPosition(), 0;

    is $xc4.findvalue('position()'), 0;

    is $xc4.findvalue('last()'), 0;

    $xc4.setContextSize(4);

    is $xc4.getContextSize(), 4;

    is $xc4.getContextPosition(), 1;

    is $xc4.findvalue('last()'), 4;

    is $xc4.findvalue('position()'), 1;
    dies-ok { $xc4.setContextPosition(5); };

    is $xc4.findvalue('position()'), 1;

    is $xc4.getContextSize(), 4;
    $xc4.setContextPosition(4);

    is $xc4.findvalue('position()'), 4;

    ok $xc4.findvalue('position()=last()');

    $xc4.setContextSize(-1);

    is $xc4.getContextPosition(), -1;

    is $xc4.getContextSize(), -1;
    dies-ok { $xc4.findvalue('position()') };
    dies-ok { $xc4.findvalue('last()') };
}

subtest 'Ns override', {
    my $d = LibXML.parse: :string(q~<x:a xmlns:x="http://x.com" xmlns:y="http://x1.com"><x1:a xmlns:x1="http://x1.com"/></x:a>~);
    my LibXML::XPath::Context $x = $d.create: LibXML::XPath::Context;

    # use the document's declaration
    is $x.findvalue('count(/x:a/y:a)', $d.documentElement), 1;

    $x.registerNs('x', 'http://x1.com');
    # x now maps to http://x1.com, so it won't match the top-level element

    is $x.findvalue('count(/x:a)', $d.documentElement), 0;

    $x.registerNs('x1', 'http://x.com');
    # x1 now maps to http://x.com
    # x1:a will match the first element
    is $x.findvalue('count(/x1:a)',$d.documentElement), 1;
    # but not the second
    is $x.findvalue('count(/x1:a/x1:a)',$d.documentElement), 0;
    # this will work, though
    is $x.findvalue('count(/x1:a/x:a)',$d.documentElement), 1;
    # the same using y for http://x1.com
    is $x.findvalue('count(/x1:a/y:a)',$d.documentElement), 1;
    $x.registerNs('y', 'http://x.com');
    # y prefix remapped
    is $x.findvalue('count(/x1:a/y:a)',$d.documentElement), 0;
    is $x.findvalue('count(/y:a/x:a)',$d.documentElement), 1;
    $x.registerNs('y', 'http://x1.com');
    # y prefix remapped back
    is $x.findvalue('count(/x1:a/y:a)',$d.documentElement), 1;
    $x.unregisterNs('x');
    is $x.findvalue('count(/x:a)',$d.documentElement), 1;
    $x.unregisterNs('y');
    is $x.findvalue('count(/x:a/y:a)',$d.documentElement), 1;
}

subtest 'document fragments', {
    my LibXML::DocumentFragment $frag .= new: config => LibXML::Config.new;
    my LibXML::Element $foo = $frag.create(LibXML::Element, 'foo');
    my LibXML::XPath::Context $xpc = $frag.create(LibXML::XPath::Context);
    $frag.appendChild($foo);
    $foo.appendTextChild('bar', 'quux');
    {
        my @n = $xpc.findnodes('./foo', $frag);
        is +@n, 1;
    }
    {
        my @n = $xpc.findnodes('./foo/bar', $frag);
        is +@n, 1;
    }
    {
        my @n = $xpc.findnodes('./bar', $foo);
        is +@n, 1;
    }
}
                                   
