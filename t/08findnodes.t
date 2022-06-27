use v6;
use Test;
plan 13;

use LibXML;
use LibXML::Parser::Context;
use LibXML::Document;
use LibXML::Element;
use LibXML::Node;

my $file    = "samples/dromeds.xml";

# init the file parser
my LibXML:D $parser .= new();
my LibXML::Document:D $dom = $parser.parse: :$file;

LibXML::Parser::Context.SetGenericErrorFunc(-> $fmt, |c { });

subtest 'findnodes basic', {
    # get the root document
    my LibXML::Element $elem = $dom.getDocumentElement();

    # first very simple path starting at root
    my LibXML::Node @list = $elem.findnodes( "species" );
    is +@list, 3;
    # a simple query starting somewhere ...
    my LibXML::Node $node = @list[0];
    my LibXML::Node @slist = $node.find( "humps" );
    is +@slist, 1;
    @slist = $node.findnodes( "HUMPS" );
    is +@slist, 0, 'case sensitivity';
    ok $node.ACCEPTS('self::species');
    ok 'self::species' ~~ $node, '.ACCEPTS()';
    ok 'humps' ~~ $node, '.ACCEPTS()';
    ok 'HUMPS' !~~ $node, '.ACCEPTS()';

    @slist = $node.findnodes('/dromedaries/species/humps');
    is +@slist, 3, 'absolute path on relative node';

    @slist = $node.findnodes('./humps');
    is +@slist, 1, 'self path on relative name';

    # find a single node
    @list   = $elem.findnodes( "species[\@name='Llama']" );
    is +@list, 1;

    # find with not conditions
    @list   = $elem.findnodes( "species[\@name!='Llama']/disposition" );
    is +@list, 2;

    @list   = $elem.findnodes( 'species/@name' );

    if @list {
        is @list[0].gist, 'name="Camel"', 'Attribute selection';
    }
    else {
        flunk('Attribute selection');
    }
    @list   = $elem<species/@name>;
    if @list {
        is @list[0].gist, 'name="Camel"', 'Attribute selection';
    }
    else {
        flunk('Attribute selection (AT-KEY)');
    }

    my LibXML::Text $x .= new: :content(1234);
    with $x {
        is( .getData(), "1234", 'getData' );
    }
    else {
        flunk("getData");
    }

    {
        my %species = $elem.findnodes( 'species/@name' ).Hash;
        is-deeply %species.keys.sort, ("@name",);
        is %species<@name>[0].Str, "Camel";
        is %species<@name>[1].Str, "Llama";
    }

    {
        my %species = $elem<species>.Hash;
        is-deeply %species.keys.sort, ("@name", "disposition", "humps", "text()");
        is %species<@name>[0].Str, "Camel";
        is %species<@name>[1].Str, "Llama";
    }

    my $telem = $dom.createElement('test');
    $telem.appendWellBalancedChunk('<B>c</B>');
    is $telem, '<test><B>c</B></test>';
    is $telem.keys, ("B",);
    is $telem<B>, '<B>c</B>';
    is $telem<B>[0].keys, ("text()",);
    ok ! $telem<b>;

    finddoc($dom);
    pass(' TODO : Add test name');
}

for 0..3 {
    my LibXML::Document:D $doc = LibXML.parse: :string(q:to<EOT>);
    <?xml version="1.0" encoding="UTF-8"?>
    <?xsl-stylesheet type="text/xsl" href="a.xsl"?>
    <a />
    EOT
    my $pi = $doc.first("processing-instruction('xsl-stylesheet')");
    is $pi.xpath-key, 'processing-instruction()';
}

my LibXML::Document:D $doc = $parser.parse: :string(q:to<EOT>);
<a:foo xmlns:a="http://foo.com" xmlns:b="http://bar.com">
 <b:bar>
  <a:foo xmlns:a="http://other.com"/>
 </b:bar>
</a:foo>
EOT
my LibXML::Element:D $root = $doc.getDocumentElement;

subtest 'ns findnodes', {
    my @a = $root.findnodes('//a:foo');

    is +@a, 1;

    my @b = $root.findnodes('//b:bar');

    is +@b, 1;

    dies-ok {@b = $root.findnodes('//B:bar')};
    @b = $root.findnodes('//b:BAR');
    is +@b, 0;

    lives-ok {@b = $root.findnodes('//B:bar', :ns{ B => "http://bar.com" })};
    is +@b, 1;

    lives-ok {@b = $root.findnodes('//b:foo', :ns{ b => "http://foo.com" })};
    is +@b, 1;

    my @none = $root.findnodes('//b:foo');
    @none.push($_) for $root.findnodes('//foo');

    is +@none, 0;
}

my @doc = $root.findnodes('document("samples/test.xml")');
ok +@doc;

# this query should result an empty array!
my @nodes = $root.findnodes( "/humpty/dumpty" );

is +@nodes, 0, 'empty result';

my $docstring = q{
<foo xmlns="http://kungfoo" xmlns:bar="http://foo"/>
};
 $doc = $parser.parse: :string( $docstring );
 $root = $doc.documentElement;

my @ns = $root.findnodes('namespace::*');

is +@ns, 2, 'Find namespace nodes';

subtest  'bad xpaths', {
    my @badxpath = (
        'abc:::def',
        'foo///bar',
        '...',
        '/-',
    );

    for @badxpath -> $xp {
        dies-ok { $root.findnodes( $xp ); }, "findnodes('$xp'); - dies";
        dies-ok { $root.find( $xp ); }, "find('$xp'); - dies";
        dies-ok { $root.findvalue( $xp ); }, "findvalue('$xp'); - dies";
    }
}

subtest 'dom interaction', {
    my $doc = LibXML.createDocument();
    my $root= $doc.createElement( "A" );
    $doc.setDocumentElement($root);

    my $b= $doc.createElement( "B" );
    $root.appendChild( $b );

    my @list = $doc.findnodes( '//A' );
    ok( @list, ' TODO : Add test name' );
    ok( @list[0].isSameNode( $root ), ' TODO : Add test name' );

    @list = $doc.findnodes( '//B' );
    ok( @list, ' TODO : Add test name' );
    ok( @list[0].isSameNode( $b ), ' TODO : Add test name' );


    @list = $doc.getElementsByTagName( "A" );
    ok( @list );
    ok( @list[0].isSameNode( $root ) );

    @list = $root.getElementsByTagName( 'B' );
    ok( @list, ' TODO : Add test name' );
    ok( @list[0].isSameNode( $b ), ' TODO : Add test name' );
}

subtest 'findnode/unbindNoode', {
    # test potential unbinding-segfault-problem
    my $doc = LibXML.createDocument();
    my $root= $doc.createElement( "A" );
    $doc.setDocumentElement($root);

    my $b= $doc.createElement( "B" );
    $root.appendChild( $b );
    my $c= $doc.createElement( "C" );
    $b.appendChild( $c );
    $b= $doc.createElement( "B" );
    $root.appendChild( $b );
    $c= $doc.createElement( "C" );
    $b.appendChild( $c );

    my @list = $root.findnodes( "B" );
    is( +@list, 2, ' TODO : Add test name' );
    for @list -> $node {
        my @subnodes = $node.findnodes( "C" );
        $node.unbindNode() if @subnodes;
        pass(' TODO : Add test name');
    }
}

subtest 'findnode/remove', {
    my $xmlstr = "<a><b><c>1</c><c>2</c></b></a>";

    my $doc       = $parser.parse: :string( $xmlstr );
    my $root      = $doc.documentElement;
    my ( $lastc ) = $root.findnodes( 'b/c[last()]' );
    ok( $lastc, ' TODO : Add test name' );

    $root.removeChild( $lastc );
    is( $root.Str(), $xmlstr, 'findnode/remove' );
}

# --------------------------------------------------------------------------- #
sub finddoc($doc) {
    return unless $doc.defined;
    my $rn = $doc.documentElement;
    $rn.findnodes("/");
}
