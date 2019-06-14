use Test;
plan 100;

use LibXML;
use LibXML::Reader;
use LibXML::Enums;
use LibXML::Document;
use LibXML::RelaxNG;
use LibXML::Schema;

unless LibXML.have-reader {
    skip-rest "LibXML Reader not supported in this libxml2 build";
}

pass "loaded LibXML::Reader";


my $file = "test/textReader/countries.xml";
{
  my $reader = LibXML::Reader.new(location => $file, expand-entities => 1);
  isa-ok($reader, "LibXML::Reader");
  is($reader.read, True, "read");
  is($reader.byteConsumed, 488, "byteConsumed");
  is($reader.attributeCount, 0, "attributeCount");
  is($reader.baseURI, $file, "baseURI");
  is($reader.encoding, 'UTF-8', "encoding");
  is($reader.localName, 'countries', "localName");
  is($reader.name, 'countries', "name");
  is($reader.prefix, Str, "prefix");
  is($reader.value, Str, "value");
  is($reader.xmlLang, Str, "xmlLang");
  is($reader.xmlVersion, '1.0', "xmlVersion");
  $reader.read;
  $reader.read;
  $reader.read;		# skipping to country node
  is($reader.name, 'country', "skipping to country");
  is($reader.depth, "1", "depth");
  is($reader.getAttribute("acronym"), "AL", "getAttribute");
  is($reader.getAttributeNo(0), "AL", "getAttributeNo");
  is($reader.getAttributeNs("acronym", Str), "AL", "getAttributeNs");
  is($reader.lineNumber, "20", "lineNumber");
  is($reader.columnNumber, "1", "columnNumber");
  ok($reader.hasAttributes, "hasAttributes");
  ok(! $reader.hasValue, "hasValue");
  ok(! $reader.isDefault, "isDefault");
  ok(! $reader.isEmptyElement, "isEmptyElement");
  ok(! $reader.isNamespaceDecl, "isNamespaceDecl");
  ok(! $reader.isValid, "isValid");
  is($reader.localName, "country", "localName");
  is($reader.lookupNamespace(Str), Str, "lookupNamespace");

  ok($reader.moveToAttribute("acronym"), "moveToAttribute");
  ok($reader.moveToAttributeNo(0), "moveToAttributeNo");
  ok($reader.moveToAttributeNs("acronym", Str), "moveToAttributeNs");

  ok($reader.moveToElement, "moveToElement");

  ok($reader.moveToFirstAttribute, "moveToFirstAttribute");
  ok($reader.moveToNextAttribute, "moveToNextAttribute");
  ok($reader.readAttributeValue, "attributeValue");

  $reader.moveToElement;
  is($reader.name, "country", "name");
  is($reader.namespaceURI, Str, "namespaceURI");

  ok($reader.nextSibling, "nextSibling");

  is($reader.nodeType, +XML_READER_TYPE_SIGNIFICANT_WHITESPACE, "nodeType");
  is-deeply($reader.prefix, Str, "prefix");

  is($reader.readInnerXml, "", "readInnerXml");
  is($reader.readOuterXml, "\n", "readOuterXml");
  ok($reader.readState, "readState");

  is($reader.getParserProp('expand-entities'), 1, "getParserProp");

  ok($reader.standalone, "standalone");
  is($reader.value, "\n", "value");
  is-deeply($reader.xmlLang, Str, "xmlLang");

  ok($reader.close, "close");
}

# FD interface
my IO::Handle:D $io = $file.IO.open: :r;
my UInt:D $fd = $io.native-descriptor;
for :$fd, :$io -> Pair:D $how {
    my $reader = LibXML::Reader.new(|$how, URI => $file);
    isa-ok($reader, "LibXML::Reader");
    $reader.read;
    $reader.read;
    is($reader.name, "countries","name in fd");
    $reader.read;
    $reader.read;
    $reader.read;
    close $io;
}

# string interface
{
    my Str $doc = $file.IO.slurp;
    my $reader = LibXML::Reader.new(string => $doc, URI => $file);
    isa-ok($reader, "LibXML::Reader");
    $reader.read;
    $reader.read;
    is($reader.name, "countries","name in string");
}

# DOM
{
  my LibXML::Document:D $DOM = LibXML.new.parse: :file($file);
  my $reader = LibXML::Reader.new(:$DOM);
  isa-ok($reader, "LibXML::Reader");
  $reader.read;
  $reader.read;
  is($reader.name, "countries","name in string");
  ok($reader.document,"document");
  ok($reader.document.isSameNode($DOM),"document is DOM");
}

# Expand
{
  my ($node1,$node2, $node3);
  my $xml = q:to<EOF>;
<root>
  <AA foo="FOO"> text1 <inner/> </AA>
  <DD/><BB bar="BAR">text2<CC> xx </CC>foo<FF/> </BB>x
  <EE baz="BAZ"> xx <PP>preserved</PP> yy <XX>FOO</XX></EE>
  <a/>
  <b/>
  <x:ZZ xmlns:x="foo"/>
  <QQ/>
  <YY/>
</root>
EOF
  {
    my $reader = LibXML::Reader.new(string => $xml);
    $reader.preservePattern('//PP');
    $reader.preservePattern('//x:ZZ', :x<foo>);

    isa-ok($reader, "LibXML::Reader");
    $reader.nextElement;
    is($reader.name, "root","root node");
    $reader.nextElement;
    is($reader.name, "AA","nextElement");

    $node1 = $reader.copyCurrentNode(:deep);
    is($node1.nodeName, "AA","deep copy node");

    $reader.next;
    ok($reader.nextElement("DD"),"next named element");
    is($reader.name, "DD","name");
    is($reader.readOuterXml, "<DD/>","readOuterXml");
    ok($reader.read,"read");
    is($reader.name, "BB","name");
    $node2 = $reader.copyCurrentNode();
    is($node2.nodeName, "BB","shallow copy node");
    $reader.nextElement;
    is($reader.name, "CC","nextElement");
    $reader.nextSibling;
    is( $reader.nodeType(), +XML_READER_TYPE_TEXT, "text node" );
    is( $reader.value,"foo", "text content" );
    $reader.skipSiblings;
    is( $reader.nodeType(), +XML_READER_TYPE_END_ELEMENT, "end element type" );
    $reader.nextElement;
    is($reader.name, "EE","name");
    ok($reader.nextSiblingElement("ZZ","foo"),"namespace");
    is($reader.namespaceURI, "foo","namespaceURI");
    $reader.nextElement;

    $node3 = $reader.preserveNode;
    is( $reader.readOuterXml(), $node3.Str, "outer xml");
    ok($node3,"preserve node");

    $reader.finish;
    my $doc = $reader.document;
    ok($doc, "document");
    ok($doc.documentElement, "doc root element");
    is($doc.documentElement.Str, q{<root><EE baz="BAZ"><PP>preserved</PP></EE><x:ZZ xmlns:x="foo"/><QQ/></root>},
       "preserved content");
  }

  ok($node1.hasChildNodes,"copy w/  child nodes");
  is($node1.Str(),q{<AA foo="FOO"> text1 <inner/> </AA>});
  ok(!defined($node2.firstChild), "copy w/o child nodes");
  is($node2.Str(),q{<BB bar="BAR"/>});
  is($node3.Str(),q{<QQ/>});
}

{
  my $bad_xml = q:to<EOF>;
<root>
  <foo/>
  <x>
     foo
  </u>
  <x>
    foo
  </x>
</root>
EOF

my $reader = LibXML::Reader.new(
    string => $bad_xml,
    URI => "mystring.xml"
   );
throws-like { $reader.finish; }, X::LibXML::Parser, :message(/'mystring.xml:5:'/),
      'caught the error';
}

{
  my $rng = "test/relaxng/demo.rng";
  for $rng, LibXML::RelaxNG.new(location => $rng) -> $RNG {
    {
      my $reader = LibXML::Reader.new(
	location => "test/relaxng/demo.xml",
	RelaxNG => $RNG,
       );
      ok($reader.finish, "validate using "~($RNG.isa(LibXML::RelaxNG) ?? 'LibXML::RelaxNG' !! 'RelaxNG file'));
    }
    {
      my $reader = LibXML::Reader.new(
	location => "test/relaxng/invaliddemo.xml",
	RelaxNG => $RNG,
       );
      throws-like { $reader.finish }, X::LibXML::Parser, :message(/'Relax-NG validity error'/);
    }

  }
}

if !LibXML.have-schemas {
    skip "https://github.com/shlomif/libxml2-2.9.4-reader-schema-regression", 4;
}
else {
    my $xsd = "test/schema/schema.xsd";
    for $xsd, LibXML::Schema.new(location => $xsd) -> $XSD {
        {
            my $reader = LibXML::Reader.new(
	        location => "test/schema/demo.xml",
	        Schema => $XSD,
            );
            ok($reader.finish, "validate using "~($XSD.isa(LibXML::Schema) ?? 'LibXML::Schema' !! 'Schema file'));
        }
        {
            my $reader = LibXML::Reader.new(
	        location => "test/schema/invaliddemo.xml",
	        Schema => $XSD,
            );
            throws-like { $reader.finish }, X::LibXML::Parser, :message(/'Schemas validity error'/);
        }
    }
}

skip "todo port tests", 6;
=begin TODO

# Patterns
{
  my ($node1,$node2, $node3);
  my $xml = <<'EOF';
<root>
  <AA foo="FOO"> text1 <inner/> </AA>
  <DD/><BB bar="BAR">text2<CC> xx </CC>foo<FF/> </BB>x
  <EE baz="BAZ"> xx <PP>preserved</PP> yy <XX>FOO</XX></EE>
  <a/>
  <b/>
  <x:ZZ xmlns:x="foo"/>
  <QQ/>
  <YY/>
</root>
EOF
  my $pattern = LibXML::Pattern.new('//inner|CC|/root/y:ZZ',{y=>'foo'});
  ok($pattern);
  {
    my $reader = LibXML::Reader.new(string => $xml);
    ok($reader);
    my $matches='';
    while ($reader.read) {
      if ($reader.matchesPattern($pattern)) {
	$matches.=$reader.nodePath.',';
      }
    }
    ok($matches,'/root/AA/inner,/root/BB/CC,/root/*,');
  }
  {
    my $reader = LibXML::Reader.new(string => $xml);
    ok($reader);
    my $matches='';
    while ($reader.nextPatternMatch($pattern)) {
      $matches.=$reader.nodePath.',';
    }
    ok($matches,'/root/AA/inner,/root/BB/CC,/root/*,');
  }
  {
    my $dom = LibXML.new.parse_string($xml);
    ok($dom);
    my $matches='';
    for $dom.findnodes('//node()|@*') -> $node {
      if ($pattern.matchesNode($node)) {
	$matches ~ =$node.nodePath ~',';
      }
    }
    ok($matches,'/root/AA/inner,/root/BB/CC,/root/*,');
  }
}

=end TODO
