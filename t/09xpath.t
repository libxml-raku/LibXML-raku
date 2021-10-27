use v6;
use Test;
plan 11;

use LibXML;
use LibXML::Document;
use LibXML::XPath::Expression;

my $xmlstring = q:to<EOSTR>;
<foo>
    <bar>
        test 1
    </bar>
    <!-- test -->    
    <bar att="val">
        test 2
    </bar>
</foo>
EOSTR

{
    my $parser = LibXML.new();

    my $doc = $parser.parse: :string( $xmlstring );

    ok $doc.defined, 'Parsing successful.';

    subtest 'findnodes', {
        my @nodes = $doc.findnodes( "/foo/bar" );
        is( +@nodes, 2, 'Two bar nodes' );

        ok( $doc.isSameNode(@nodes[0].ownerDocument),
            'Doc is the same as the owner document.' );

        my $compiled = LibXML::XPath::Expression.parse("/foo/bar");
        for (1..3) -> $idx {
            @nodes = $doc.findnodes( $compiled );
            is( +@nodes, 2, "Two nodes for /foo/bar - try No. $idx" );
        }

        my $comment = $doc.first('/foo/comment()');
        is $comment, '<!-- test -->';
        is $comment.xpath-key, 'comment()';
        ok( $doc.isSameNode(@nodes[0].ownerDocument),
            'Same owner as previous one',
        );

        my $n = $doc.createElement( "foobar" );

        my $p = @nodes[1].parentNode;
        $p.insertBefore( $n, @nodes[1] );


        ok( $p.isSameNode( $doc.documentElement ), 'Same as document elem' );
        @nodes = $p.childNodes;
        is( +@nodes, 8, 'Found child nodes' );
    }

    subtest 'find', {
        my $result = $doc.find( "/foo/bar" );
        ok $result;
        isa-ok $result, "LibXML::Node::Set";
        skip("numeric on nodes");
        is +$result, 2;


        ok $doc.isSameNode($result.iterator.pull-one.ownerDocument);

        $result = $doc.find( LibXML::XPath::Expression.parse("/foo/bar") );
        ok $result.defined;
        isa-ok $result, "LibXML::Node::Set";
        skip("numeric on nodes");
        is +$result, 2;
        {
            my $node = $doc.last("/foo/bar");
            is $node.find('ancestor-or-self::*').map(*.nodePath).join(','), '/foo,/foo/bar[2]';
            is $node.find('ancestor-or-self::*').reverse.map(*.nodePath).join(','), '/foo/bar[2],/foo';
        }

        ok $doc.isSameNode($result.iterator.pull-one.ownerDocument);

        $result = $doc.find( "string(/foo/bar)" );
        ok $result.defined;
        ok $result.isa(Str);
        ok $result ~~ /'test 1'/;

        $result = $doc.find( "string(/foo/bar)" );
        ok $result.defined;
        ok $result.isa(Str);
        ok $result ~~ /'test 1'/;

        $result = $doc.find( LibXML::XPath::Expression.parse("count(/foo/bar)") );
        ok $result.defined;
        todo("https://github.com/rakudo/rakudo/issues/4485");
        ok $result.isa( Numeric );
        is $result, 2;

        $result = $doc.find( "contains(/foo/bar[1], 'test 1')" );
        ok $result.defined;
        ok $result.isa( Bool );
        is-deeply $result, True;

        $result = $doc.find( LibXML::XPath::Expression.parse("contains(/foo/bar[1], 'test 1')") );
        ok $result.defined;
        ok $result.isa( Bool );
        is-deeply $result, True;

        $result = $doc.find( "contains(/foo/bar[3], 'test 1')" );
        is-deeply $result, False;


        ok $doc.exists("/foo/bar[2]");
        is-deeply $doc.exists("/foo/bar[3]"), False;
        is-deeply $doc.exists("-7.2"), True;
        is-deeply $doc.exists("0"), False;
        is-deeply $doc.exists("'foo'"), True;
        is-deeply $doc.exists("''"), False;
        is-deeply $doc.exists("'0'"), True;

        my $node = $doc.first("/foo/bar[1]" );
        ok $node.defined;
        ok $node.exists("following-sibling::bar");
    }

    subtest 'attribute', {
        my $result = $doc.find( "/foo/bar/@att" );
        ok $result;
        my $node = $result[0];
        isa-ok $node, 'LibXML::Attr';
        is $node.nodePath, '/foo/bar[2]/@att';
    }

    subtest 'removeChild', {
        my $root = $doc.documentElement();
        for $root.findnodes( 'bar' ) -> $bar {
            $root.removeChild($bar);
        }
        pass 'remove from root';

        $doc =  $parser.parse: :string( $xmlstring );
        my @bars = $doc.findnodes( '//bar' );

        for @bars -> $node {
            $node.parentNode().removeChild( $node );
        }
        pass 'remove from parent';
    }

    subtest 'find numeric', {
        my $root = $doc.root;
        is $root.findvalue('42'), 42;
        is $root.find('42'), 42;
        isa-ok $root.findnodes('42'), 'LibXML::Node::Set';
        is-deeply $root.first('42'), LibXML::Node;
        is-deeply $root.last('42'), LibXML::Node;
    }
}



subtest 'Perl #39178', {
    my $p = LibXML.new;
    my $doc = $p.parse: :file("samples/utf-16-2.xml");
    ok $doc.defined;
    my @nodes = $doc.findnodes("/cml/*");
    is +@nodes, 2;
    is @nodes[1].textContent, "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]";
}

subtest 'Perl #36576', {
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("samples/utf-16-1.html");
    ok $doc.defined;
    my @nodes = $doc.findnodes("//p");
    is +@nodes, 1;

    _utf16_content_test(@nodes, 'nodes content is fine.');
}

subtest 'Perl #36576', {
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("samples/utf-16-2.html");
    ok $doc.defined;
    my @nodes = $doc.findnodes("//p");
    is +@nodes, 1, 'Found one p';
    _utf16_content_test(@nodes, 'p content is fine.');
}

subtest 'Perl #69096', {
    my $doc = LibXML::Document.createDocument();
    my $root = $doc.createElement('root');
    $doc.setDocumentElement($root);
    my $e = $doc.createElement("child");
    my $e2 = $doc.createElement("child");
    my $t1 = $doc.createTextNode( "te" );
    my $t2 = $doc.createTextNode( "st" );
    $root.appendChild($e);
    $root.appendChild($e2);
    $e2.appendChild($t1);
    $e2.appendChild($t2);

    $doc.normalize();
    my @cn = $doc.findnodes('//child[text()="test"]');
    is +@cn, 1, 'xpath testing adjacent text nodes';
}

sub _utf16_content_test
{

    my ($nodes_ref, $blurb) = @_;

    is($nodes_ref[0].textContent,
       "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]",
       $blurb,
      );
}

subtest '#42 root parent from xpath', {
    plan 2;
    my LibXML::Document $doc .= parse("<root/>");
    my LibXML::Document $doc2;
    lives-ok {$doc2 = .parent for $doc.find("//*");};
    ok $doc.isSameNode($doc2);
}
