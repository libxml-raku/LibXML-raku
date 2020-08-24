use v6;
use LibXML::Dict;
use Test;
plan 12;

my LibXML::Dict $dict .= new;

is $dict.elems, 0, 'dict initial size';
$dict<a> = 'a';
$dict.see('b');
$dict.see: <c D>;

is $dict.elems, 4, 'dict updated size';

ok $dict<a>:exists;
nok $dict<d>:exists; 
nok $dict<d>:exists;
ok $dict<D>:exists;

is $dict<a>, 'a';
is-deeply $dict<d>, Str;
is-deeply $dict<d>, Str;

my $e = 'e';
dies-ok {$dict<e> := $e};
is $dict.elems, 4, 'dict updated size';

$dict<e> = $e;
is $dict.elems, 5, 'dict updated size';

