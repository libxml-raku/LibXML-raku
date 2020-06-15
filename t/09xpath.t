use v6;
use Test;
plan 65;

use LibXML;
use LibXML::XPath::Expression;

my $xmlstring = q:to<EOSTR>;
<foo>
    <bar>
        test 1
    </bar>
    <!-- test -->    
    <bar>
        test 2
    </bar>
</foo>
EOSTR

{
    my $parser = LibXML.new();

    my $doc = $parser.parse: :string( $xmlstring );

    ok($doc, 'Parsing successful.');

    {
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

    {
        my $result = $doc.find( "/foo/bar" );
        ok( $result, ' TODO : Add test name' );
        isa-ok( $result, "LibXML::Node::Set", ' TODO : Add test name' );
        skip("numeric on nodes");
        is( +$result, 2, ' TODO : Add test name' );


        ok( $doc.isSameNode($result.iterator.pull-one.ownerDocument), ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("/foo/bar") );
        ok( $result, ' TODO : Add test name' );
        isa-ok( $result, "LibXML::Node::Set", ' TODO : Add test name' );
        skip("numeric on nodes");
        is( +$result, 2, ' TODO : Add test name' );
        {
            my $node = $doc.last("/foo/bar");
            is $node.find('ancestor-or-self::*').map(*.nodePath).join(','), '/foo,/foo/bar[2]';
            is $node.find('ancestor-or-self::*').reverse.map(*.nodePath).join(','), '/foo/bar[2],/foo';
        }

        ok( $doc.isSameNode($result.iterator.pull-one.ownerDocument), ' TODO : Add test name' );

        $result = $doc.find( "string(/foo/bar)" );
        ok( $result, ' TODO : Add test name' );
        ok( $result.isa(Str), ' TODO : Add test name' );
        ok( $result ~~ /'test 1'/, ' TODO : Add test name' );

        $result = $doc.find( "string(/foo/bar)" );
        ok( $result, ' TODO : Add test name' );
        ok( $result.isa(Str), ' TODO : Add test name' );
        ok( $result.Str ~~ /'test 1'/, ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("count(/foo/bar)") );
        ok( $result, ' TODO : Add test name' );
        todo("returning num64?");
        ok( $result.isa( Numeric ), ' TODO : Add test name' );
        is( $result, 2, ' TODO : Add test name' );

        $result = $doc.find( "contains(/foo/bar[1], 'test 1')" );
        ok( $result, ' TODO : Add test name' );
        ok( $result.isa( Bool ), ' TODO : Add test name' );
        is( $result, True, ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("contains(/foo/bar[1], 'test 1')") );
        ok( $result, ' TODO : Add test name' );
        ok( $result.isa( Bool ), ' TODO : Add test name' );
        is( $result, True, ' TODO : Add test name' );

        $result = $doc.find( "contains(/foo/bar[3], 'test 1')" );
        is( $result, False, ' TODO : Add test name' );


        ok( $doc.exists("/foo/bar[2]"), ' TODO : Add test name' );
        is( $doc.exists("/foo/bar[3]"), False, ' TODO : Add test name' );
        is( $doc.exists("-7.2"), True, ' TODO : Add test name' );
        is( $doc.exists("0"), False, ' TODO : Add test name' );
        is( $doc.exists("'foo'"), True, ' TODO : Add test name' );
        is( $doc.exists("''"), False, ' TODO : Add test name' );
        is( $doc.exists("'0'"), True, ' TODO : Add test name' );

        my $node = $doc.first("/foo/bar[1]" );
        ok( $node, ' TODO : Add test name' );
        ok ($node.exists("following-sibling::bar"), ' TODO : Add test name');
    }

    {
        # test the strange segfault after xpathing
        my $root = $doc.documentElement();
        for ( $root.findnodes( 'bar' )  ) -> $bar {
            $root.removeChild($bar);
        }
        pass(' TODO : Add test name');
        # warn $root.toString();

        $doc =  $parser.parse: :string( $xmlstring );
        my @bars = $doc.findnodes( '//bar' );

        for @bars -> $node {
            $node.parentNode().removeChild( $node );
        }
        pass(' TODO : Add test name');
    }
    {
        my $root = $doc.root;
        is $root.findvalue('42'), 42;
        is $root.find('42'), 42;
        isa-ok $root.findnodes('42'), LibXML::Node::Set;
        is-deeply $root.first('42'), LibXML::Node;
        is-deeply $root.last('42'), LibXML::Node;
    }
}



{
    # from Perl 5 #39178
    my $p = LibXML.new;
    my $doc = $p.parse: :file("example/utf-16-2.xml");
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("/cml/*");
    ok (@nodes == 2, ' TODO : Add test name');
    is(@nodes[1].textContent, "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]", ' TODO : Add test name');
}

{
    # from Perl 5 #36576
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("example/utf-16-1.html");
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("//p");
    ok (@nodes == 1, ' TODO : Add test name');

    _utf16_content_test(@nodes, 'nodes content is fine.');
}

{
    # from Perl 5 #36576
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("example/utf-16-2.html");
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("//p");
    is(+@nodes, 1, 'Found one p');
    _utf16_content_test(@nodes, 'p content is fine.');
}

{
    # from Perl 5 #69096
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
    is( +@cn, 1, 'xpath testing adjacent text nodes' );
}

sub _utf16_content_test
{

    my ($nodes_ref, $blurb) = @_;

    SKIP:
    {
        is($nodes_ref[0].textContent,
            "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]",
            $blurb,
        );
    }
}

