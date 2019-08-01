use v6;
use Test;
use LibXML::Hash;

plan 12;

my LibXML::Hash $h .= new;

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

done-testing;
