use v6;
use Test;
use LibXML::HashMap;
use LibXML::Element;
use LibXML::Document;
use LibXML::Node::Set;
use NativeCall;

plan 4;

subtest 'Str HashMaps' => {
    plan 17;
    my LibXML::HashMap[Str] $h .= new;
    is-deeply $h.of, Str;
    is $h.elems, 0;
    lives-ok {$h<Xx> = 'Hi'};
    is $h.elems, 1;
    is $h<Xx>, 'Hi';
    is-deeply $h<Yy>, Str;
    lives-ok {$h<Xx> = 'Again'};
    is $h.elems, 1;
    is $h<Xx>, 'Again';
    $h<Xx>:delete;
    is $h<Xx>, Str;
    is $h.elems, 0;
    $h<Xx> = 42;
    is-deeply $h<Xx>, '42';
    $h<yy> = "xx";

    is-deeply $h.keys.sort, ("Xx", "yy");
    is-deeply $h.values.sort, ("42", "xx");
    is-deeply $h.pairs.sort, (Xx => "42", yy => "xx");

    my CArray[Str] $pairs .= new("a", "A", "b", "B");
    my LibXML::HashMap[Str] $h1 .= new: :$pairs;
    is-deeply $h1.pairs.sort, (a => "A", b => "B");
    is-deeply $h1.kv.sort, ("A", "B", "a", "b");
}

subtest 'Int HashMaps' => {
    plan 3;
    my LibXML::HashMap[Int] $h .= new;
    is-deeply $h.of, Int;
    $h<Xx> = 42;
    is-deeply $h<Xx>, 42;
    is-deeply $h.kv, ("Xx", 42);
}

my LibXML::Element $node .= new('test');

subtest 'LibXML::Item HashMaps' => {
    plan 3;
    my LibXML::HashMap[LibXML::Element] $h .= new;

    lives-ok {$h<elem> = $node};
    is-deeply $h.keys, ("elem", );
    ok $node.isSame($h.kv[1]);
}

subtest 'LibXML::Node::Set HashMaps' => {
    plan 4;
    my LibXML::HashMap[LibXML::Node::Set] $h .= new;
    my LibXML::Node::Set $set .= new;
    $set.add: $node;
    lives-ok {$h<elem> = $set};
    isa-ok $h.of, LibXML::Node::Set;
    is-deeply $h.keys, ("elem", );
    ok $node.isSame($h.kv[1][0]);
}

done-testing;
