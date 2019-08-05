use v6;
use Test;
use LibXML::HashMap;
use LibXML::Element;
use LibXML::XPath::Object :XPathDomain;
use NativeCall;

plan 18;

my LibXML::HashMap[XPathDomain] $h .= new;
is-deeply $h.of, XPathDomain;
is $h.elems, 0;
lives-ok { $h<Xx> = 'Hi';};
is $h.elems, 1;
is $h<Xx>, 'Hi';
is-deeply $h<Yy>, Any;
lives-ok {$h<Xx> = 'Again'};
is $h.elems, 1;
is $h<Xx>, 'Again';
$h<Xx>:delete;
is $h<Xx>, Any;
is $h.elems, 0;
$h<Xx> = 42;
is-deeply $h<Xx>, 42e0;
$h<yy> = "xx";

is-deeply $h.keys.sort, ("Xx", "yy");
is-deeply $h.values.sort, (42e0, "xx");
is-deeply $h.pairs.sort, (Xx => 42e0, yy => "xx");

my LibXML::Element $node .= new('test');

lives-ok {$h<elems> = $node;};
is-deeply $h.keys.sort, ("Xx", "elems", "yy");
ok $node.isSame($h<elems>[0]);

done-testing;
