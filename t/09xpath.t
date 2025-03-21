use v6;
use Test;
plan 10;

use LibXML;
use LibXML::Document;
use LibXML::Element;
use LibXML::Node;
use LibXML::Text;
use LibXML::Node::Set;
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
    my LibXML $parser .= new();

    my LibXML::Document:D $doc = $parser.parse: :string( $xmlstring );

    subtest 'findnodes', {
        my @nodes = $doc.findnodes( "/foo/bar" );
        is +@nodes, 2, 'Two bar nodes';
        ok @nodes[0] ~~ @nodes[0];
        nok @nodes[0] ~~ @nodes[1];

        ok( $doc.isSameNode(@nodes[0].ownerDocument),
            'Doc is the same as the owner document.' );

        my LibXML::XPath::Expression $compiled .= parse("/foo/bar");
        for (1..3) -> $idx {
            @nodes = $doc.findnodes( $compiled );
            is +@nodes, 2, "Two nodes for /foo/bar - try No. $idx" ;
        }

        my $comment = $doc.first('/foo/comment()');
        is $comment, '<!-- test -->';
        is $comment.xpath-key, 'comment()';
        ok $doc.isSameNode(@nodes[0].ownerDocument), 'Same owner as previous one';

        my $n = $doc.createElement( "foobar" );

        my $p = @nodes[1].parentNode;
        $p.insertBefore( $n, @nodes[1] );


        ok $p.isSameNode( $doc.documentElement ), 'Same as document elem';
        @nodes = $p.childNodes;
        is( +@nodes, 8, 'Found child nodes' );
    }

    subtest 'find', {
        my LibXML::Node::Set:D $result = $doc.find( "/foo/bar" );
        skip("numeric on nodes");
        is +$result, 2;

        ok $doc.isSameNode($result.iterator.pull-one.ownerDocument);

        $result = $doc.find( LibXML::XPath::Expression.parse("/foo/bar") );
        is +$result, 2;
        {
            my LibXML::Element:D $node = $doc.last("/foo/bar");
            is $node.find('ancestor-or-self::*').map(*.nodePath).join(','), '/foo,/foo/bar[2]';
            is $node.find('ancestor-or-self::*').reverse.map(*.nodePath).join(','), '/foo/bar[2],/foo';
        }

        ok $doc.isSameNode($result.iterator.pull-one.ownerDocument);

        my Str:D $str-result = $doc.find( "string(/foo/bar)" );
        ok $str-result ~~ /'test 1'/;

        $str-result = $doc.find( "string(/foo/bar)" );
        ok $str-result ~~ /'test 1'/;

        my Numeric:D $num-result = $doc.find( LibXML::XPath::Expression.parse("count(/foo/bar)") );
        is $num-result, 2;

        my Bool:D $bool-result = $doc.find( "contains(/foo/bar[1], 'test 1')" );
        is-deeply $bool-result, True;

        $bool-result = $doc.find( LibXML::XPath::Expression.parse("contains(/foo/bar[1], 'test 1')") );
        is-deeply $bool-result, True;

        $bool-result = $doc.find( "contains(/foo/bar[3], 'test 1')" );
        is-deeply $bool-result, False;

        ok $doc.exists("/foo/bar[2]");
        is-deeply $doc.exists("/foo/bar[3]"), False;
        is-deeply $doc.exists("-7.2"), True;
        is-deeply $doc.exists("0"), False;
        is-deeply $doc.exists("'foo'"), True;
        is-deeply $doc.exists("''"), False;
        is-deeply $doc.exists("'0'"), True;

        my LibXML::Element:D $node = $doc.first("/foo/bar[1]" );
        ok $node.exists("following-sibling::bar");
    }

    subtest 'attribute', {
        my LibXML::Node::Set:D $result = $doc.find( "/foo/bar/@att" );
        ok $result.defined;
        my $node = $result[0];
        isa-ok $node, 'LibXML::Attr';
        is $node.nodePath, '/foo/bar[2]/@att';
    }

    subtest 'removeChild', {
        my LibXML::Element:D $root = $doc.documentElement();
        for $root.findnodes( 'bar' ) -> $bar {
            $root.removeChild($bar);
        }
        pass 'remove from root';

        $doc = $parser.parse: :string( $xmlstring );
        my LibXML::Element @bars = $doc.findnodes( '//bar' );

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
    my LibXML:D $p .= new;
    my LibXML::Document:D $doc = $p.parse: :file("samples/utf-16-2.xml");
    my LibXML::Element @nodes = $doc.findnodes("/cml/*");
    is +@nodes, 2;
    is @nodes[1].textContent, "utf-16 test with umlauts: \x[e4]\x[f6]\x[fc]\x[c4]\x[d6]\x[dc]\x[df]";
}

subtest 'Perl #36576', {
    my LibXML:D $p .= new;
    my LibXML::Document:D $doc = $p.parse: :html, :file("samples/utf-16-1.html");
    my LibXML::Element:D @nodes = $doc.findnodes("//p");
    is +@nodes, 1;

    _utf16_content_test(@nodes, 'nodes content is fine.');
}

subtest 'Perl #36576', {
    my LibXML:D $p .= new;
    my LibXML::Document:D $doc = $p.parse: :html, :file("samples/utf-16-2.html");
    my LibXML::Element:D @nodes = $doc.findnodes("//p");
    is +@nodes, 1, 'Found one p';
    _utf16_content_test(@nodes, 'p content is fine.');
}

subtest 'Perl #69096', {
    my LibXML::Document:D $doc .= createDocument();
    my LibXML::Element:D $root = $doc.createElement('root');
    $doc.setDocumentElement($root);
    my LibXML::Element:D $e = $doc.createElement("child");
    my LibXML::Element:D $e2 = $doc.createElement("child");
    my LibXML::Text:D $t1 = $doc.createTextNode( "te" );
    my LibXML::Text:D $t2 = $doc.createTextNode( "st" );
    $root.appendChild($e);
    $root.appendChild($e2);
    $e2.appendChild($t1);
    $e2.appendChild($t2);

    $doc.normalize();
    my LibXML::Node:D @cn = $doc.findnodes('//child[text()="test"]');
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
