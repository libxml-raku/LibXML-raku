use v6;
use Test;
use LibXML::Hash;

plan 17;

my LibXML::Hash[Str] $h .= new;
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

my LibXML::Hash[UInt] $h2 .= new;
is-deeply $h2.of, UInt;
$h2<Xx> = 42;
is-deeply $h2<Xx>, 42;

done-testing;
