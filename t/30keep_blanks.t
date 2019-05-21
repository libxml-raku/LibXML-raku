# This is a regression test for this bug:
#
# https://rt.cpan.org/Ticket/Display.html?id=76696
#
# <<<
# Specifying ->keep_blanks(0) has no effect on parse_balanced_chunk anymore.
# The script below used to pass with XML::LibXML 1.69, but is broken since
# 1.70 and also with the newest 1.96.
# >>>
#
# Thanks to SREZIC for the report, the test and a patch.

use Test;
use LibXML;

plan 2;

my $xml = q:to<EOF>;
<bla> <foo/> </bla>
EOF

my $p = LibXML.new;
$p.keep-blanks = True;

# TEST
is(
    $p.parse-balanced( :string($xml)).serialize(),
    "<bla> <foo/> </bla>\n",
    'keep-blanks keeps the blanks after a roundtrip.',
);

$p.keep-blanks = False;

# TEST
is(
    $p.parse-balanced( :string($xml)).serialize(),
    "<bla><foo/></bla>\n",
    '!keep-blanks removes the blanks after a roundtrip.',
);
