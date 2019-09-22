use v6.c;

use Test;
use LibXML;

plan 1;

my $x = LibXML.parse(string => q:to/ENDXML/);
<xml xmlns="http://foobar.example.com">
    <foo>
        <bar/>
        <foo/>
    </foo>
</xml>
ENDXML

my $nodes = $x.find("//*[ namespace-uri() = 'http://foobar.example.com' ]");
is $nodes.elems, 4, 'found 4 nodes';

done-testing;
