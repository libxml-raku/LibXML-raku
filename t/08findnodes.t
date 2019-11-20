use v6;
use Test;
plan 56;

use LibXML;

# to test if findnodes works.
# i added findnodes to the node class, so a query can be started
# everywhere.

my $file    = "example/dromeds.xml";

# init the file parser
my $parser = LibXML.new();
my $dom    = $parser.parse: :$file;

LibXML::ErrorHandling.SetGenericErrorFunc(-> $fmt, |c { });

if defined $dom {
    # get the root document
    my $elem   = $dom.getDocumentElement();

    # first very simple path starting at root
    my @list   = $elem.findnodes( "species" );
    is( +@list, 3, ' TODO : Add test name' );
    # a simple query starting somewhere ...
    my $node = @list[0];
    my @slist = $node.find( "humps" );
    is( +@slist, 1, ' TODO : Add test name' );
    @slist = $node.findnodes( "HUMPS" );
    is( +@slist, 0, 'case sensitivity');

    # find a single node
    @list   = $elem.findnodes( "species[\@name='Llama']" );
    is( +@list, 1, ' TODO : Add test name' );

    # find with not conditions
    @list   = $elem.findnodes( "species[\@name!='Llama']/disposition" );
    is( +@list, 2, ' TODO : Add test name' );


    @list   = $elem.findnodes( 'species/@name' );
    # warn $elem.Str();


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
    is $telem.keys, ("B",);
    is $telem<B>, '<B>c</B>';
    ok ! $telem<b>;

    finddoc($dom);
    pass(' TODO : Add test name');
}

ok( $dom, ' TODO : Add test name' );

for 0..3 {
    my $doc = LibXML.parse: :string(
'<?xml version="1.0" encoding="UTF-8"?>
<?xsl-stylesheet type="text/xsl" href="a.xsl"?>
<a />');
    my @nds = $doc.findnodes("processing-instruction('xsl-stylesheet')");
    is @nds[0].xpath-key, 'processing-instruction()';

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

is(+@a, 1, ' TODO : Add test name');

my @b = $root.findnodes('//b:bar');

is(+@b, 1, ' TODO : Add test name');

dies-ok {@b = $root.findnodes('//B:bar')};
@b = $root.findnodes('//b:BAR');
is(+@b, 0, ' TODO : Add test name');

my @none = $root.findnodes('//b:foo');
@none.push($_) for $root.findnodes('//foo');

is(+@none, 0, ' TODO : Add test name');

my @doc = $root.findnodes('document("example/test.xml")');

ok(+@doc, ' TODO : Add test name');
# warn($doc[0].Str);

# this query should result an empty array!
my @nodes = $root.findnodes( "/humpty/dumpty" );

is( +@nodes, 0, 'Empty array' );

my $docstring = q{
<foo xmlns="http://kungfoo" xmlns:bar="http://foo"/>
};
 $doc = $parser.parse: :string( $docstring );
 $root = $doc.documentElement;

my @ns = $root.findnodes('namespace::*');

is(+@ns, 2, 'Find namespace nodes' );

# bad xpaths
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
    is( +@list, 2, ' TODO : Add test name' );
    for @list -> $node {
        my @subnodes = $node.findnodes( "C" );
        $node.unbindNode() if @subnodes;
        pass(' TODO : Add test name');
    }
}

{
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
