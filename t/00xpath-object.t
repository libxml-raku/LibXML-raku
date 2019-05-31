use v6;
use Test;
use LibXML;
use LibXML::Document;
use LibXML::Native;
use LibXML::Node::Set;
use LibXML::Enums;

plan 27;

my xmlXPathObject $xo .= coerce(42);
is $xo.type, +XPATH_NUMBER;
is-approx $xo.float, 42;
is-approx $xo.select, 42;

$xo .= coerce(42.1);
is $xo.type, +XPATH_NUMBER;
is-approx $xo.float, 42.1;
is-approx $xo.select, 42.1;

$xo .= coerce(Inf);
is $xo.type, +XPATH_NUMBER;
is xmlXPathIsInf($xo.float), 1;
is-deeply $xo.select, Inf;

$xo .= coerce(-Inf);
is $xo.type, +XPATH_NUMBER;
my int32 $is-inf = xmlXPathIsInf($xo.float);
is $is-inf, -1;
is-deeply $xo.select, -Inf;

$xo .= coerce(NaN);
is $xo.type, +XPATH_NUMBER;
ok xmlXPathIsNaN($xo.float);
is-deeply $xo.select, NaN;

$xo .= coerce(True);
is $xo.type, +XPATH_BOOLEAN;           
is-deeply $xo.select, True;

$xo .= coerce('Zsófia');
is $xo.type, +XPATH_STRING;
is $xo.select, 'Zsófia';

my LibXML::Document $doc = LibXML.load: :string("<a><b/><c/><d/></a>");
my LibXML::Node::Set:D $nodes = $doc.find('*/*');
is $nodes.size, 3;

$xo .= coerce($nodes.native);
is  $xo.type, +XPATH_NODESET;
is-deeply $xo.select, $nodes.native;

$xo .= coerce($nodes[1].native);
is  $xo.type, +XPATH_NODESET;
my $val = $xo.select;
isa-ok $val, xmlNodeSet;
# expect a one-element set, that contains the node
my  LibXML::Node::Set $set .= new: :range(LibXML::Node), :native($val);
is $set.size, 1;
isa-ok $set[0], LibXML::Node;
is $set[0].Str, '<c/>';

done-testing();

