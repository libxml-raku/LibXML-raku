use v6;
# Having 'XML_PARSE_HUGE' enabled can make an application vulnerable to
# denial of service through entity expansion attacks.  This test script
# confirms that huge document mode is disabled by default and that this
# does not adversely affect expansion of sensible entity definitions.
#

use Test;
use LibXML;
use LibXML::Document;

plan 4;

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
 <!ENTITY lol "lolXXXX">
 <!ENTITY lol1 "&lol;&lol;">
 <!ENTITY lol2 "&lol1;&lol1;">
 <!ENTITY lol3 "&lol2;&lol2;">
 <!ENTITY lol4 "&lol3;&lol3;">
 <!ENTITY lol5 "&lol4;&lol4;">
 <!ENTITY lol6 "&lol5;&lol5;">
 <!ENTITY lol7 "&lol6;&lol6;">
 <!ENTITY lol8 "&lol7;&lol7;">
 <!ENTITY lol9 "&lol8;&lol8;">
 <!ENTITY lolA "&lol9;&lol9;">
 <!ENTITY lolB "&lolA;&lolA;">
 <!ENTITY lolC "&lolB;&lolB;">
 <!ENTITY lolD "&lolC;&lolC;">
 <!ENTITY lolE "&lolD;&lolD;">
 <!ENTITY lolF "&lolE;&lolE;">
 <!ENTITY lolG "&lolF;&lolF;">
 <!ENTITY lolH "&lolG;&lolG;">
]>
<lolz>&lolH;</lolz>
EOF

my LibXML $parser .= new;
#$parser->set_option(huge => 0);
ok !$parser.get-option('huge'), "huge mode disabled by default";

throws-like { my $xml = $parser.parse: :string($evil_xml), :expand-entities; note $xml.Str.chars }, X::LibXML::Parser, :message(/entity/), "exception thrown during parse";

$parser .= new;

my LibXML::Document $doc;
lives-ok { $doc = $parser.parse: :string($benign_xml); }, "no exception thrown during parse";

my $body = $doc.findvalue( '/lolz' );
is $body, 'haha', 'entity was parsed and expanded correctly';

exit;

