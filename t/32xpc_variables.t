use v6;
use Test;
plan 11;

use LibXML;
use LibXML::XPath::Context;
use LibXML::Enums;

# silence tests
my $errors;
LibXML::XPath::Context.SetGenericErrorFunc(-> $ctx, $fmt, |c { $errors++ });

my $doc = LibXML.parse: :string(q:to<XML>);
<foo><bar a="b">Bla</bar><bar/></foo>
XML

my %variables = (
    'a' => 2,
    'b' => "b",
);

sub get_variable($name, $uri ) {
    %variables{$name};
}

# $c: node list
subtest 'nodelist', {
    %variables<c> = $doc.create(LibXML::XPath::Context, :$doc).findnodes('//bar');
    isa-ok %variables<c>, 'LibXML::Node::Set';
    is %variables<c>.size(), 2;
    is %variables<c>[1].nodeName, 'bar';
}

# $d: a single element node
%variables<d> = $doc.create(LibXML::XPath::Context, :$doc).findnodes('/*').pop;
is %variables<d>.nodeName(), 'foo', 'single element node';

# $e: a single text node
%variables<e> = $doc.create(LibXML::XPath::Context, :$doc).findnodes('//text()');
is %variables<e>[0].data(), 'Bla', 'single text node';

# $f: a single attribute node
%variables<f> = $doc.create(LibXML::XPath::Context, :$doc).findnodes('//@*').pop;
is %variables<f>.nodeName(), 'a', 'single attribute node';
is %variables<f>.value(), 'b', 'single attribute node';

# $f: a single document node
%variables<g> = $doc.create(LibXML::XPath::Context, :$doc).first('/');
is %variables<g>.nodeType(), +XML_DOCUMENT_NODE, 'single document node';

my LibXML::XPath::Context $xc = $doc.create(LibXML::XPath::Context, :$doc);
# test registerVarLookupFunc() and getVarLookupData()
subtest 'xpath context find', {

    ##ok(!defined($xc.getVarLookupData), ' TODO : Add test name');
    $xc.registerVarLookupFunc(&get_variable);
    skip('varLookupData - do we need this?', 5);
    ##ok(defined($xc.getVarLookupData), ' TODO : Add test name');
    ##my $h1=$xc.getVarLookupData;
    ##my $h2=\%variables;
    ##ok("$h1" eq "$h2", ' TODO : Add test name' );
    ##ok($h1 eq $xc.getVarLookupData, ' TODO : Add test name');
    ##is-deeply(\&get_variable, $xc.getVarLookupFunc, ' TODO : Add test name');

    # test values returned by XPath queries
    is $xc.find('$a'), 2, 'find int';
    is $xc.find('$b'), "b", 'find string';
    subtest 'findnodes' =>  {
        is $xc.findnodes('//@a[.=$b]').size(), 1;
        is $xc.findnodes('//@a[.=$b]').size(), 1;

        is $xc.findnodes('$c').size(), 2;
        is $xc.findnodes('$c').size(), 2;
        ok $xc.findnodes('$c[1]').pop.isSameNode(%variables<c>[0]);
        is $xc.findnodes('$c[@a="b"]').size(), 1;
        is $xc.findnodes('$d').size(), 1;
        is $xc.findnodes('$d/*').size(), 2;
        ok $xc.findnodes('$d').pop.isSameNode(%variables<d>);
        ok $xc.findvalue('$e') eq 'Bla';
        ok $xc.findnodes('$e').pop.isSameNode(%variables<e>[0]);
        is $xc.findnodes('$c[@*=$f]').size(), 1;
        is $xc.findvalue('$f'), 'b';
        is $xc.findnodes('$f').pop.nodeName, 'a';
        ok $xc.findnodes('$f').pop.isSameNode(%variables<f>);
        ok $xc.findnodes('$g').pop.isSameNode(%variables<g>),;
    }
}
# unregiser variable lookup
$xc.unregisterVarLookupFunc();
dies-ok { $xc.find('$a') }, 'unregisterVarLookupFunc()';
ok !defined($xc.getVarLookupFunc()), 'unregisterVarLookupFunc()';

skip('varLookupData - do we need this?', 2);
##my $foo='foo';
##$xc.registerVarLookupFunc(sub {},$foo);
##ok($xc.getVarLookupData eq 'foo', ' TODO : Add test name');
##$foo=undef;
##ok($xc.getVarLookupData eq 'foo', ' TODO : Add test name');

