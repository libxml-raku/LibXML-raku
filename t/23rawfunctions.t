use v6;
use Test;
plan 2;
use LibXML;

my $doc = LibXML.createDocument;

my $t1 = $doc.createTextNode( "foo" );
my $t2 = $doc.createTextNode( "bar" );

$t1.addChild( $t2 );

lives-ok {
    my Str:D $v = $t2.nodeValue;
};

# TEST
ok(1, 'End');
