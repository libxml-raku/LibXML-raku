use v6;
use Test;
plan 41;

use LibXML;

# to test if findnodes works.
# i added findnodes to the node class, so a query can be started
# everywhere.

my $file    = "example/dromeds.xml";

# init the file parser
my $parser = LibXML.new();
my $dom    = $parser.parse: :$file;

if ( defined $dom ) {
    # get the root document
    my $elem   = $dom.getDocumentElement();

    # first very simple path starting at root
    my @list   = $elem.findnodes( "species" );
    # TEST
    is( +@list, 3, ' TODO : Add test name' );
    # a simple query starting somewhere ...
    my $node = @list[0];
    my @slist = $node.findnodes( "humps" );
    # TEST
    is( +@slist, 1, ' TODO : Add test name' );

    # find a single node
    @list   = $elem.findnodes( "species[\@name='Llama']" );
    # TEST
    is( +@list, 1, ' TODO : Add test name' );

    # find with not conditions
    @list   = $elem.findnodes( "species[\@name!='Llama']/disposition" );
    # TEST
    is( +@list, 2, ' TODO : Add test name' );


    @list   = $elem.findnodes( 'species/@name' );
    # warn $elem.Str();

    # TEST

    if @list {
        is(@list[0].gist, 'name="Camel"', 'Attribute selection' )
    }
    else {
        flunk('Attribute selection');
    }
    @list   = $elem<species/@name>;
    if @list {
        is(@list[0].gist, 'name="Camel"', 'Attribute selection' )
    }
    else {
        flunk('Attribute selection (AT-KEY)');
    }

    my $x = LibXML::Text.new: :content(1234);
    with $x {
        # TEST
        is( .getData(), "1234", 'getData' );
    }
    else {
        flunk("getData");
    }

    {
        my %species = $elem.findnodes( 'species/@name' ).Hash;
        is-deeply %species.keys.sort, ("name",);
        is %species<name>[0].Str, "Camel";
        is %species<name>[1].Str, "Llama";
    }

    my $telem = $dom.createElement('test');
    $telem.appendWellBalancedChunk('<b>c</b>');

    finddoc($dom);
    # TEST
    ok(1, ' TODO : Add test name');
}
# TEST

ok( $dom, ' TODO : Add test name' );

# test to make sure that multiple array findnodes() returns
# don't segfault perl; it'll happen after the second one if it does
for (0..3) {
    my $doc = LibXML.parse: :string(
'<?xml version="1.0" encoding="UTF-8"?>
<?xsl-stylesheet type="text/xsl" href="a.xsl"?>
<a />');
    my @nds = $doc.findnodes("processing-instruction('xsl-stylesheet')");
}

my $doc = $parser.parse: :string(q:to<EOT>);
<a:foo xmlns:a="http://foo.com" xmlns:b="http://bar.com">
 <b:bar>
  <a:foo xmlns:a="http://other.com"/>
 </b:bar>
</a:foo>
EOT

my $root = $doc.getDocumentElement;
my @a = $root.findnodes('//a:foo');
# TEST

is(+@a, 1, ' TODO : Add test name');

my @b = $root.findnodes('//b:bar');
# TEST

is(+@b, 1, ' TODO : Add test name');

my @none = $root.findnodes('//b:foo');
@none.push($_) for $root.findnodes('//foo');
# TEST

is(+@none, 0, ' TODO : Add test name');

my @doc = $root.findnodes('document("example/test.xml")');
# TEST

ok(+@doc, ' TODO : Add test name');
# warn($doc[0].Str);

# this query should result an empty array!
my @nodes = $root.findnodes( "/humpty/dumpty" );
# TEST

is( +@nodes, 0, 'Empty array' );

my $docstring = q{
<foo xmlns="http://kungfoo" xmlns:bar="http://foo"/>
};
 $doc = $parser.parse: :string( $docstring );
 $root = $doc.documentElement;

my @ns = $root.findnodes('namespace::*');
# TEST

is(+@ns, 2, 'Find namespace nodes' );

# bad xpaths
# TEST:$badxpath=4;
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


{
    # as reported by jian lou:
    # 1. getElementByTagName("myTag") is not working is
    # "myTag" is a node directly under root. Same problem
    # for findNodes("//myTag")
    # 2. When I add new nodes into DOM tree by
    # appendChild(). Then try to find them by
    # getElementByTagName("newNodeTag"), the newly created
    # nodes are not returned. ...
    #
    # this seems not to be a problem by LibXML itself, but newer versions
    # of libxml2 (newer is 2.4.27 or later)
    #
    my $doc = LibXML.createDocument();
    my $root= $doc.createElement( "A" );
    $doc.setDocumentElement($root);

    my $b= $doc.createElement( "B" );
    $root.appendChild( $b );

    my @list = $doc.findnodes( '//A' );
    # TEST
    ok( @list, ' TODO : Add test name' );
    # TEST
    ok( @list[0].isSameNode( $root ), ' TODO : Add test name' );

    @list = $doc.findnodes( '//B' );
    # TEST
    ok( @list, ' TODO : Add test name' );
    # TEST
    ok( @list[0].isSameNode( $b ), ' TODO : Add test name' );


    # @list = $doc.getElementsByTagName( "A" );
    # ok( @list );
    # ok( $list[0].isSameNode( $root ) );

    @list = $root.getElementsByTagName( 'B' );
    # TEST
    ok( @list, ' TODO : Add test name' );
    # TEST
    ok( @list[0].isSameNode( $b ), ' TODO : Add test name' );
}

{
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
    # TEST
    is( +@list, 2, ' TODO : Add test name' );
    for @list -> $node {
        my @subnodes = $node.findnodes( "C" );
        $node.unbindNode() if @subnodes;
        # TEST*2
        ok(1, ' TODO : Add test name');
    }
}

{
    # findnode remove problem

    my $xmlstr = "<a><b><c>1</c><c>2</c></b></a>";

    my $doc       = $parser.parse: :string( $xmlstr );
    my $root      = $doc.documentElement;
    my ( $lastc ) = $root.findnodes( 'b/c[last()]' );
    # TEST
    ok( $lastc, ' TODO : Add test name' );

    $root.removeChild( $lastc );
    # TEST
    is( $root.Str(), $xmlstr, 'findnode/remove' );
}

# --------------------------------------------------------------------------- #
sub finddoc($doc) {
    return unless $doc.defined;
    my $rn = $doc.documentElement;
    $rn.findnodes("/");
}
