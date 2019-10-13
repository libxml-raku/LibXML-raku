use v6;
use Test;
plan 56;

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

    # TEST
    ok($doc, 'Parsing successful.');

    {
        my @nodes = $doc.findnodes( "/foo/bar" );
        # TEST
        is( +@nodes, 2, 'Two bar nodes' );

        # TEST
        ok( $doc.isSameNode(@nodes[0].ownerDocument),
            'Doc is the same as the owner document.' );

        my $compiled = LibXML::XPath::Expression.parse("/foo/bar");
        for (1..3) -> $idx {
            @nodes = $doc.findnodes( $compiled );
            # TEST*3
            is( +@nodes, 2, "Two nodes for /foo/bar - try No. $idx" );
        }

        my $comments = $doc.findnodes('/foo/comment()');
        is $comments, '<!-- test -->';
        is $comments[0].xpath-key, 'comment()';
        # TEST
        ok( $doc.isSameNode(@nodes[0].ownerDocument),
            'Same owner as previous one',
        );

        my $n = $doc.createElement( "foobar" );

        my $p = @nodes[1].parentNode;
        $p.insertBefore( $n, @nodes[1] );

        # TEST

        ok( $p.isSameNode( $doc.documentElement ), 'Same as document elem' );
        @nodes = $p.childNodes;
        # TEST
        is( +@nodes, 8, 'Found child nodes' );
    }

    {
        my $result = $doc.find( "/foo/bar" );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        isa-ok( $result, "LibXML::Node::Set", ' TODO : Add test name' );
        # TEST
        skip("numeric on nodes");
##        is( +$result, 2, ' TODO : Add test name' );

        # TEST

        ok( $doc.isSameNode($result.pull-one.ownerDocument), ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("/foo/bar") );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        isa-ok( $result, "LibXML::Node::Set", ' TODO : Add test name' );
        # TEST
        skip("numeric on nodes");
##        is( +$result, 2, ' TODO : Add test name' );

        # TEST

        ok( $doc.isSameNode($result.pull-one.ownerDocument), ' TODO : Add test name' );

        $result = $doc.find( "string(/foo/bar)" );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        ok( $result.isa(Str), ' TODO : Add test name' );
        # TEST
        ok( $result ~~ /'test 1'/, ' TODO : Add test name' );

        $result = $doc.find( "string(/foo/bar)" );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        ok( $result.isa(Str), ' TODO : Add test name' );
        # TEST
        ok( $result.Str ~~ /'test 1'/, ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("count(/foo/bar)") );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        todo("returning num64?");
        ok( $result.isa( Numeric ), ' TODO : Add test name' );
        # TEST
        is( $result, 2, ' TODO : Add test name' );

        $result = $doc.find( "contains(/foo/bar[1], 'test 1')" );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        ok( $result.isa( Bool ), ' TODO : Add test name' );
        # TEST
        is( $result, True, ' TODO : Add test name' );

        $result = $doc.find( LibXML::XPath::Expression.parse("contains(/foo/bar[1], 'test 1')") );
        # TEST
        ok( $result, ' TODO : Add test name' );
        # TEST
        ok( $result.isa( Bool ), ' TODO : Add test name' );
        # TEST
        is( $result, True, ' TODO : Add test name' );

        $result = $doc.find( "contains(/foo/bar[3], 'test 1')" );
        # TEST
        is( $result, False, ' TODO : Add test name' );

        # TEST

        ok( $doc.exists("/foo/bar[2]"), ' TODO : Add test name' );
        # TEST
        is( $doc.exists("/foo/bar[3]"), False, ' TODO : Add test name' );
        # TEST
        is( $doc.exists("-7.2"), True, ' TODO : Add test name' );
        # TEST
        is( $doc.exists("0"), False, ' TODO : Add test name' );
        # TEST
        is( $doc.exists("'foo'"), True, ' TODO : Add test name' );
        # TEST
        is( $doc.exists("''"), False, ' TODO : Add test name' );
        # TEST
        is( $doc.exists("'0'"), True, ' TODO : Add test name' );

        my ($node) = $doc.findnodes("/foo/bar[1]" );
        # TEST
        ok( $node, ' TODO : Add test name' );
        # TEST
        ok ($node.exists("following-sibling::bar"), ' TODO : Add test name');
    }

    {
        # test the strange segfault after xpathing
        my $root = $doc.documentElement();
        for ( $root.findnodes( 'bar' )  ) -> $bar {
            $root.removeChild($bar);
        }
        # TEST
        ok(1, ' TODO : Add test name');
        # warn $root.toString();

        $doc =  $parser.parse: :string( $xmlstring );
        my @bars = $doc.findnodes( '//bar' );

        for @bars -> $node {
            $node.parentNode().removeChild( $node );
        }
        # TEST
        ok(1, ' TODO : Add test name');
    }
}


{
    # from #39178
    my $p = LibXML.new;
    my $doc = $p.parse: :file("example/utf-16-2.xml");
    # TEST
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("/cml/*");
    # TEST
    ok (@nodes == 2, ' TODO : Add test name');
    # TEST
    is(@nodes[1].textContent, "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]", ' TODO : Add test name');
}

{
    # from #36576
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("example/utf-16-1.html");
    # TEST
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("//p");
    # TEST
    ok (@nodes == 1, ' TODO : Add test name');

    # TEST
    _utf16_content_test(@nodes, 'nodes content is fine.');
}

{
    # from #36576
    my $p = LibXML.new;
    my $doc = $p.parse: :html, :file("example/utf-16-2.html");
    # TEST
    ok($doc, ' TODO : Add test name');
    my @nodes = $doc.findnodes("//p");
    # TEST
    is(+@nodes, 1, 'Found one p');
    # TEST
    _utf16_content_test(@nodes, 'p content is fine.');
}

{
    # from #69096
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
    # TEST
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

