use v6;
use Test;
use LibXML::HashMap;
use LibXML::Element;
use LibXML::Enums;
use LibXML::Config;
use LibXML::Types :XPathRange;
use NativeCall;

plan 2;

subtest 'node-hash' => {
    plan 4;
    my $config = LibXML::Config.new;
    my LibXML::HashMap[LibXML::Element] $elems .= new(:$config);

    for 1 .. 5 {
        $elems{'e'~$_} .= new('Elem' ~ $_, :$config);
    }

    is-deeply [$elems.keys.sort], [(1..5).map('e'~*)], 'keys';
    is-deeply [$elems.values.map(*.Str).sort], [(1..5).map({'<Elem'~$_~'/>'})], 'values';

    $elems<e5>:delete;
    nok $elems<e5>:exists, 'deleted element';
    $elems<e4> .= new('Replaced', :$config);
    is $elems<e4>.Str, '<Replaced/>', 'replaced element';
}

subtest 'object-hash' => {
    plan 20;

    my $config = LibXML::Config.new;
    my LibXML::HashMap[XPathRange] $h .= new(:$config);
    is-deeply $h.of, XPathRange;
    is $h.elems, 0;
    lives-ok { $h<Xx> = 'Hi';};
    is $h.elems, 1;
    is $h<Xx>, 'Hi';
    is-deeply $h<Yy>, XPathRange;
    lives-ok {$h<Xx> = 'Again'};
    is $h.elems, 1;
    is $h<Xx>, 'Again';
    $h<Xx>:delete;
    is $h<Xx>, XPathRange;
    is $h.elems, 0;
    $h<Xx> = 42;
    is-deeply $h<Xx>, 42e0;
    is-deeply $h<Xx>, 42e0;
    $h<x:y> = "xx";

    is-deeply $h.keys.sort, ("Xx", "x:y");
    is-deeply $h.values.sort, (42e0, "xx");
    is-deeply $h.pairs.sort, (Xx => 42e0, 'x:y' => "xx");

    my LibXML::Element $node .= new('test', :$config);

    lives-ok {$h<elem> = $node;};
    is-deeply $h.keys.sort, ("Xx", "elem", "x:y");
    ok $node.isSame($h<elem>);
    ok $h<elem>.isSame($node);
}

done-testing;
