# this test checks the DOM Character data interface of XML::LibXML

use v6;
use Test;
plan 65;

use LibXML;
use LibXML::Text;

my $doc = LibXML::Document.new();

{
    # 1. creation
    my $foo = "foobar";
    my LibXML::Text $textnode = $doc.createTextNode($foo);
    ok( $textnode, 'creation 1');
    is( $textnode.nodeName(), '#text',  'creation 2');
    is( $textnode.nodeValue(), $foo,  'creation 3',);

    nok $textnode.attributes(), 'Attributes NO-OP on text nodes';

    # 2. substring
    my $tnstr = $textnode.substringData( 1,2 );
    is( $tnstr , "oo", 'substring 1');
    $tnstr = $textnode.substringData( 0,3 );
    is( $tnstr , "foo", 'substring 2');
    is( $textnode.nodeValue(), $foo,  'substring - text node unchanged' );

    # 3. Expansion
    $textnode.appendData( $foo );
    is( $textnode.nodeValue(), $foo ~ $foo, 'expansion 1');

    $textnode.insertData( 6, "FOO" );
    is( $textnode.nodeValue(), $foo~"FOO"~$foo, 'expansion 2' );

    $textnode.setData( $foo );
    $textnode.insertData( 6, "FOO" );
    is( $textnode.nodeValue(), $foo~"FOO", 'expansion 3');

    $textnode.setData( $foo );
    $textnode.insertData( 3, "" );
    is( $textnode.nodeValue(), $foo, 'Empty insertion does not change value');

    # 4. Removal
    $textnode.deleteData( 1,2 );
    is( $textnode.nodeValue(), "fbar", 'Removal 1');
    $textnode.setData( $foo );
    $textnode.deleteData( 1,10 );
    is( $textnode.nodeValue(), "f", 'Removal 2');
    $textnode.setData( $foo );
    $textnode.deleteData( 10,1 );
    is( $textnode.nodeValue(), $foo, 'Removal 3');
    $textnode.deleteData( 1,0 );
    is( $textnode.nodeValue(), $foo, 'Removal 4');
    $textnode.deleteData( 0,0 );
    is( $textnode.nodeValue(), $foo, 'Removal 5');
    $textnode.deleteData( 0,2 );
    is( $textnode.nodeValue(), "obar", 'Removal 6');

    # 5. Replacement
    $textnode.setData( "test" );
    $textnode.replaceData( 1,2, "phish" );
    is( $textnode.nodeValue(), "tphisht", 'Replacement 1');
    $textnode.setData( "test" );
    $textnode.replaceData( 1,4, "phish" );
    is( $textnode.nodeValue(), "tphish",  'Replacement 2');
    $textnode.setData( "test" );
    $textnode.replaceData( 1,0, "phish" );
    is( $textnode.nodeValue(), "tphishest",  'Replacement 3');


    # 6. LibXML features
    $textnode.setData( "test" );

    $textnode.replaceData( "es", "new" );
    is( $textnode.nodeValue(), "tnewt", 'replaceDataString() 1');
    $textnode.content ~~  s/n(.)w/{$0}s/;
    is( $textnode.nodeValue(), "test", 'replaceDataRegEx() 2');

    $textnode.setData( "blue phish, white phish, no phish" );
    $textnode.replaceData( 'phish', 'test' );
    is( $textnode.nodeValue(), "blue test, white phish, no phish",
        'replaceDataRegEx 3',);

    # replace them all!
    $textnode.replaceData( 'phish', 'test', :g );
    is( $textnode.nodeValue(), "blue test, white test, no test",
        'replaceDataRegEx g',);

    # check if special chars are encoded properly
    $textnode.setData( "te?st" );
    $textnode.replaceData( "e?s", 'ne\w' );
    is( $textnode.nodeValue(), 'tne\wt', ' TODO : Add test name' );

    # check if "." is encoded properly
    $textnode.setData( "h.thrt");
    $textnode.replaceData( "h.t", 'new',);
    is( $textnode.nodeValue(), 'newhrt', ' TODO : Add test name' );

    # check if deleteDataString does not delete dots.
    $textnode.setData( 'hitpit' );
    $textnode.deleteData( 'h.t' );
    is( $textnode.nodeValue(), 'hitpit', ' TODO : Add test name' );

    # check if deleteDataString works
    $textnode.setData( 'hitpithit' );
    $textnode.deleteData( 'hit' );
    is( $textnode.nodeValue(), 'pithit', ' TODO : Add test name' );

    # check if deleteDataString all works
    $textnode.setData( 'hitpithit' );
    $textnode.deleteData( 'hit', :g);
    is( $textnode.nodeValue(), 'pit', ' TODO : Add test name' );

    # check if entities don't get translated
    $textnode.setData('foo&amp;bar');
    is( $textnode.getData(), 'foo&amp;bar', ' TODO : Add test name' );
}

{
    # UTF-8 tests

    my $test_str  = "te\xDFt";

    # 1. creation
    my $textnode = $doc.createTextNode($test_str);
    ok( $textnode, 'UTF-8 creation 1');
    is( $textnode.nodeValue(), $test_str,  'UTF-8 creation 2',);
    my $foo_str = "\x[0444]oo\x[0431]ar";
    $textnode = $doc.createTextNode($foo_str);
    ok( $textnode, 'UTF-8 creation 3');
    is( $textnode.nodeValue(), $foo_str,  'UTF-8 creation 4',);

    # 2. substring
    my $tnstr = $textnode.substringData( 1,2 );
    is( $tnstr , "oo", 'UTF-8 substring 1');
    $tnstr = $textnode.substringData( 0,3 );
    is( $tnstr , "\x[0444]oo", 'UTF-8 substring 2');

    # 3. Expansion
    $textnode.appendData( $foo_str );
    is( $textnode.nodeValue(), $foo_str ~ $foo_str, 'UTF-8 expansion 1');

    my $ins_str = "\x[0424]OO";
    $textnode.insertData( 6, $ins_str );
    is( $textnode.nodeValue(), $foo_str ~ $ins_str ~ $foo_str,
        'UTF-8 expansion 2' );

    $textnode.setData( $foo_str );
    $textnode.insertData( 6, $ins_str );
    is( $textnode.nodeValue(), $foo_str ~ $ins_str, 'UTF-8 expansion 3');

    # 4. Removal
    $textnode.setData( $foo_str );
    $textnode.deleteData( 1,3 );
    is( $textnode.nodeValue(), "\x[0444]ar", 'UTF-8 Removal 1');
    $textnode.setData( $foo_str );
    $textnode.deleteData( 1,10 );
    is( $textnode.nodeValue(), "\x[0444]", 'UTF-8 Removal 2');
    $textnode.setData( $foo_str );
    $textnode.deleteData( 6,100 );
    is( $textnode.nodeValue(), $foo_str, 'UTF-8 Removal 3');

    # 5. Replacement
    my $phish_str = "ph\x[2160]sh";
    $textnode.setData( $test_str );
    $textnode.replaceData( 1,2, $phish_str );
    is( $textnode.nodeValue(), "t" ~ $phish_str ~ "t", 'UTF-8 Replacement 1');
    $textnode.setData( $test_str );
    $textnode.replaceData( 1,4, $phish_str );
    is( $textnode.nodeValue(), "t" ~ $phish_str, 'UTF-8 Replacement 2');
    $textnode.setData( $test_str );
    $textnode.replaceData( 1,0, $phish_str );
    is( $textnode.nodeValue(), "t" ~ $phish_str ~ "e\xDFt",
        'UTF-8 Replacement 3');

    # 6. LibXML features
    $textnode.setData( $test_str );

    my $new_str = "n\x[1D522]w";
    $textnode.replaceData( "e\xDF", $new_str );
    is( $textnode.nodeValue(), "t" ~ $new_str ~ "t",
        'UTF-8 replaceData() 1');

    $textnode.content ~~ s/n(.)w/{$0}s/;
    is( $textnode.nodeValue(), "t\x[1D522]st", 'UTF-8 replaceDataRegEx() 2');

    $textnode.setData( "blue $phish_str, white $phish_str, no $phish_str" );
    $textnode.replaceData( $phish_str, $test_str );
    is( $textnode.nodeValue(),
        "blue $test_str, white $phish_str, no $phish_str",
        'UTF-8 replaceDataRegEx 3',);

    # replace them all!
    $textnode.replaceData( $phish_str, $test_str, :g );
    is( $textnode.nodeValue(),
        "blue $test_str, white $test_str, no $test_str",
        'UTF-8 replaceDataRegEx g',);

    # check if deleteDataString works
    my $hit_str = "hi\x[1D54B]";
    my $pit_str = "\x[2119]it";
    $textnode.setData( "$hit_str$pit_str$hit_str" );
    $textnode.deleteData( $hit_str );
    is( $textnode.nodeValue(), "$pit_str$hit_str", 'UTF-8 deleteDataString 1' );

    # check if deleteDataString all works
    $textnode.setData( "$hit_str$pit_str$hit_str" );
    $textnode.deleteData( $hit_str, :g );
    is( $textnode.nodeValue(), $pit_str, 'UTF-8 deleteDataString 2' );
}

{
    # standalone test
    my $node = LibXML::Text.new: :content<foo>;
    ok($node, ' TODO : Add test name');
    is($node.nodeValue, "foo", ' TODO : Add test name' );
}

{
    # CDATA node name test

    my $node = LibXML::CDATA.new: :content<test>;

    is( $node.string-value(), "test", ' TODO : Add test name' );
    is( $node.nodeName(), "#cdata-section", ' TODO : Add test name' );
    is( $node.ast-key(), "#cdata", ' TODO : Add test name' );
}

{
    # Comment node name test

    my $node = LibXML::Comment.new: :content<test>;

    is( $node.string-value(), "test", ' TODO : Add test name' );
    is( $node.nodeName(), "#comment", ' TODO : Add test name' );
    is( $node.ast-key(), "#comment", ' TODO : Add test name' );
}

{
    # Document node name test

    my $node = LibXML::Document.new();

    is( $node.nodeName(), "#document", ' TODO : Add test name' );
    is( $node.ast-key(), "#xml", ' TODO : Add test name' );
    is( $node.xpath-key(), "document()", ' TODO : Add test name' );
}
{
    # Document fragment node name test

    my $node = LibXML::DocumentFragment.new();

    is( $node.nodeName(), "#document-fragment", ' TODO : Add test name' );
    is( $node.ast-key(), "#fragment", ' TODO : Add test name' );
    is( $node.xpath-key(), "document()", ' TODO : Add test name' );
}

