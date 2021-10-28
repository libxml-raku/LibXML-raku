use v6;
# ensure keep-blanks plays with .parse-balanced()

use Test;
use LibXML;

plan 2;

my $xml = q:to<EOF>;
<bla> <foo/> </bla>
EOF

my LibXML $p .= new;
$p.keep-blanks = True;

is(
    $p.parse-balanced( :string($xml)).serialize(),
    "<bla> <foo/> </bla>\n",
    'keep-blanks keeps the blanks after a roundtrip.',
);

$p.keep-blanks = False;

is(
    $p.parse-balanced( :string($xml)).serialize(),
    "<bla><foo/></bla>\n",
    '!keep-blanks removes the blanks after a roundtrip.',
);
