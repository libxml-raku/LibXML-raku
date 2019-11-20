use v6;
use Test;
use LibXML;
use LibXML::ErrorHandling;

plan 3;

my LibXML $p .= new;

my $xmlstr = q:to<EOX>;
<X></Y>
EOX

try {
    my $doc = $p.parse: :string( $xmlstr );
};

my $err = $!;
isa-ok($err, X::LibXML::Parser, 'Exception is of type parser error.');
is($err.domain(), 'parser', 'Error is in the parser domain');
is($err.line(), 1, 'Error is on line 1.');
