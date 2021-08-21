use v6;
use Test;
plan 1;

use LibXML;

# the following document should not be able to get parsed
# if the catalog is not available

my $doc = LibXML.new( catalog => "example/catalog.xml" ).parse: :string(q:to<EOF>);
<!DOCTYPE article
  PUBLIC "-//Perl//XML LibXML V4.1.2//EN"
  "http://axkit.org/xml-libxml/test.dtd">
<article>
<pubData>Something here</pubData>
<pubArticleID>12345</pubArticleID>
<pubDate>2001-04-01</pubDate>
<pubName>XML.com</pubName>
<section>Foo</section>
<lead>Here's some leading text</lead>
<rest>And here is the rest...</rest>
</article>
EOF

ok defined($doc), 'Doc was parsed with catalog';
