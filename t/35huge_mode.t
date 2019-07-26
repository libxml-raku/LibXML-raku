# Having 'XML_PARSE_HUGE' enabled can make an application vulnerable to
# denial of service through entity expansion attacks.  This test script
# confirms that huge document mode is disabled by default and that this
# does not adversely affect expansion of sensible entity definitions.
#

use Test;
use LibXML;

plan 4;

given LibXML.version {
    when * < v2.07.00 {
        skip-rest "XML_PARSE_HUGE option not supported for libxml2: $_ < 2.07.0";
        exit;
    }
}

my $benign_xml = q:to<EOF>;
<?xml version="1.0"?>
<!DOCTYPE lolz [
  <!ENTITY lol "haha">
]>
<lolz>&lol;</lolz>
EOF

my $evil_xml = q:to<EOF>;
<?xml version="1.0"?>
<!DOCTYPE lolz [
 <!ENTITY lol "lol">
 <!ENTITY lol1 "&lol;&lol;">
 <!ENTITY lol2 "&lol1;&lol1;">
 <!ENTITY lol3 "&lol2;&lol2;">
 <!ENTITY lol4 "&lol3;&lol3;">
 <!ENTITY lol5 "&lol4;&lol4;">
 <!ENTITY lol6 "&lol5;&lol5;">
 <!ENTITY lol7 "&lol6;&lol6;">
 <!ENTITY lol8 "&lol7;&lol7;">
 <!ENTITY lol9 "&lol8;&lol8;">
]>
<lolz>&lol9;</lolz>
EOF

my ($parser, $doc);

$parser = LibXML.new;
#$parser->set_option(huge => 0);
ok(!$parser.get-option('huge'), "huge mode disabled by default");

throws-like { $parser.parse: :string($evil_xml); }, X::LibXML::Parser, :message(/entity.*loop/), "exception thrown during parse";

$parser .= new;

lives-ok { $doc = $parser.parse: :string($benign_xml); }, "no exception thrown during parse";

my $body = $doc.findvalue( '/lolz' );
is($body, 'haha', 'entity was parsed and expanded correctly');

exit;

