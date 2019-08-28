use v6;
use Test;
use LibXML;
use LibXML::Attr;
use LibXML::Document;
use LibXML::Element;
use LibXML::RelaxNG;
constant MAX_THREADS = 24;
constant MAX_LOOP = 50;
# use constant PLAN => 24;

# TEST
ok(1, 'Loaded');

my LibXML $p .= new();
# TEST
ok($p.defined, 'Parser initted.');

sub blat(&r, :$n = MAX_THREADS) {
    (0 ..^ $n).race(:batch(1)).map(&r);
}

subtest 'relaxng' => {
  plan 3;
  my $grammar = q:to<EOF>;
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
<start>
  <element name="foo"><empty/></element>
</start>
</grammar>
EOF
  my LibXML::Document $good .= parse: :string('<foo/>');
  my LibXML::Document $bad .= parse: :string('<bar/>');
  my LibXML::RelaxNG @schemas = blat {
      LibXML::RelaxNG.new(string => $grammar);
  }
  my Bool @good = blat { @schemas[$_].is-valid($good); }
  my Bool @bad = blat { @schemas[$_].is-valid($bad); }

  is +@schemas, MAX_THREADS, 'relaxng schemas';
  is-deeply (+@good, [@good.unique]), (MAX_THREADS, [True]), 'relax-ng valid';
  is-deeply (+@bad, [@bad.unique]), (MAX_THREADS, [False]), 'relax-ng invalid';
}


{
    my X::LibXML::Parser:D @err = blat { try { LibXML.parse: :string('foo'); } for 1..100; $! };
    is @err.elems, MAX_THREADS, 'parse errors';
    ok(1, "XML error");
}

{
    my $doc = LibXML::Document.new;
    $doc.setDocumentElement($doc.createElement('root'));
    $doc.getDocumentElement.setAttribute('foo','bar');

    my LibXML::Element:D @roots = blat {
        my LibXML::Element:D @r = blat {
            $doc.getDocumentElement;
        }
        @r.pick;
    };
    is +@roots, MAX_THREADS, 'document roots';
    is @roots.unique.elems, 1, 'document root reduction';
}

# TEST
{
    my LibXML::Document:D @docs = blat {
        my $doc = LibXML::Document.new;
        $doc.setDocumentElement($doc.createElement('root'));
        $doc.getDocumentElement.setAttribute('foo','bar');
        $doc
    }
    is @docs.elems, MAX_THREADS, 'document roots';
    is @docs.unique.elems, MAX_THREADS, "unique documents don't reduce";

    my Str:D @values = blat {
        my LibXML::Document:D $doc = @docs[$_];
        my  Str:D @values = await (0 ..^ 20).map: { start {
	    # a dictionary of $doc
	    my LibXML::Element:D $el = $doc.createElement('foo' ~ $_);
	    $el.setAttribute('foo','bar');
            $doc.getDocumentElement.getAttribute('foo');
	    $el.getAttribute('foo');
        } }
        @values.pick;
    };
    is +@values, MAX_THREADS, 'att values';
    is @values.unique.elems, 1, 'att values reduction';
}
# TEST
ok(1, "operating on different documents without lock");

# operating on the same document with a lock
{
    my LibXML::Document $doc .= new;
    my LibXML::Document:D @docs = blat {
        for (1..24) {
            $doc.protect: {
                my $el = $doc.createElement('foo');
                $el.setAttribute('foo','bar');
	        $el.getAttribute('foo');
            }
        }
        $doc;
    }
    is @docs.elems, MAX_THREADS, 'document roots';
    is @docs.unique.elems, 1, 'documents reduction';
}

my $xml = q:to<EOF>;
<?xml version="1.0" encoding="utf-8"?>
<root><node><leaf/></node></root>
EOF

{
    my LibXML::Element @nodes;
    {
        my $doc = $p.parse: :string($xml);
        @nodes = blat { $doc.documentElement[0][0] }
    }
    is @nodes.elems, MAX_THREADS, 'document leaf nodes';
    is @nodes.map(*.unique-key).unique.elems, 1, 'document leaf nodes reduction';
    is @nodes.pick.Str, '<leaf/>', 'sampled node';
}

{
    my LibXML::Document @docs = blat { $p.parse: :string($xml) };
    is @docs.elems, MAX_THREADS, 'document leaf nodes';
    is @docs.map(*.unique-key).unique.elems, MAX_THREADS, 'document leaf nodes reduced by unique keys';
    is @docs.map(*.Str).unique.elems, 1, 'document leaf nodes reduced by content';
}

my $xml_bad = q:to<EOF>;
<?xml version="1.0" encoding="utf-8"?>
<root><node><leaf/></root>
EOF


{
    my X::LibXML::Parser:D @err = blat { try { my $x = $p.parse: :string($xml_bad)} for 1..100; $!; }
    is @err.elems, MAX_THREADS, 'parse errors';
}

my $xml_invalid = q:to<EOF>;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE root [
<!ELEMENT root EMPTY>
]>
<root><something/></root>
EOF

{
  my LibXML::Document:D @docs = blat {
      my $x = $p.parse: :string($xml_invalid);
      die if $x.is-valid;
      try { $x.validate };
      die unless $!;
      $x;
  }
  is @docs.elems, MAX_THREADS, 'well-formed, but invalid documents';
}

my $rngschema = q:to<EOF>;
<?xml version="1.0"?>
<r:grammar xmlns:r="http://relaxng.org/ns/structure/1.0">
  <r:start>
    <r:element name="root">
      <r:attribute name="id"/>
    </r:element>
  </r:start>
</r:grammar>
EOF

{
    blat {
        for (1..MAX_LOOP) {
	    my $x = $p.parse: :string($xml);
	    try { LibXML::RelaxNG.new( string => $rngschema ).validate( $x ) };
	    die "no error" without $!;
        }
    }
    # TEST
    ok(1, "test RNG validation errors thread safe sanity");
}

my $xsdschema = q:to<EOF>;
<?xml version="1.0"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:element name="root">
    <xsd:attribute name="partNum" type="SKU" use="required"/>
  </xsd:element>
</xsd:schema>
EOF

{
    blat {
        for (1..MAX_LOOP) {
	    my $x = $p.parse: :string($xml);
	    try { LibXML::Schema.new( string => $xsdschema ).validate( $x ) };
	    die "no error" without $!;
        }
    }
    # TEST
    ok(1, "test Schema validation errors thread safe sanity");
}

skip "port remaining tests";
done-testing();
=begin TODO

my $bigfile = "docs/libxml.dbk";
$xml = utf8_slurp($bigfile);
# TEST
ok($xml, 'bigfile was slurped fine.');
sub use_dom
{
	my $d = shift;
	my @nodes = $d.getElementsByTagName("title",1);
	for(@nodes)
	{
		my $title = $_.toString;
	}
	die unless $nodes[0].toString eq '<title>LibXML</title>';
}

{
for(1..MAX_THREADS) {
	threads.new(sub { my $dom = do { $p.parse_string($xml); }; use_dom($dom) for 1..5; 1; });
}
$_.join for(threads.list);
# TEST
ok(1, 'Joined all threads.');
}

{
package MyHandler;

use parent 'XML::SAX::Base';

sub AUTOLOAD
{
}
}

use LibXML::SAX;
$p = LibXML::SAX.new(
	Handler=>MyHandler.new(),
);
# TEST
ok($p, 'LibXML::SAX was initted.');

{
for(1..MAX_THREADS)
{
	threads.new(sub { $p.parse_string($xml) for (1..5); 1; });
}
$_.join for threads.list;

# TEST
ok(1, 'After LibXML::SAX - join.');
}

$p = LibXML.new(
	Handler=>MyHandler.new(),
);
$p.parse_chunk($xml);
$p.parse_chunk("",1);

{
for(1..MAX_THREADS)
{
	threads.new(sub {
$p = LibXML.new();
$p.parse_chunk($xml);
use_dom($p.parse_chunk("",1));
1;
});
}
$_.join for(threads.list);
# TEST
ok(1, 'LibXML thread.');
}

$p = LibXML.new();
# parse a big file using the same parser
{
for(1..MAX_THREADS)
{
	threads.new(sub {
open my $fh, '<', $bigfile
    or die "Cannot open '$bigfile'!";
my $doc = $p.parse_fh($fh);
close $fh;
2;
});
}
my @results = $_.join for(threads.list);
# TEST
ok(1, 'threads.join after opening bigfile.');
}

# create elements
{
my @n = map LibXML::Element.new('bar'.$_), 1..1000;
for(1..MAX_THREADS)
{
	threads.new(sub {
	push @n, map LibXML::Element.new('foo'.$_), 1..1000;
1;
});
}
$_.join for(threads.list);
# TEST
ok(1, 'create elements');
}

{
my $e = LibXML::Element.new('foo');
for(1..MAX_THREADS) {
  threads.new(sub {
		 if ($_[0]==1) {
		   my $d = LibXML::Document.new();
		   $d.setDocumentElement($d.createElement('root'));
		   $d.documentElement.appendChild($e);
		 }
		 1;
	       },$_);
}
$_.join for(threads.list);
# TEST
ok(1, "docfrag");
}

{
my $e = LibXML::Element.new('foo');
my $d = LibXML::Document.new();
$d.setDocumentElement($d.createElement('root'));
for(1..MAX_THREADS) {
  threads.new(sub {
		 if ($_[0]==1) {
		   $d.documentElement.appendChild($e);
		 }
		 1;
	       },$_);
}
$_.join for(threads.list);
# TEST
ok(1, "docfrag2");
}

{
my $e = LibXML::Element.new('foo');
for(1..MAX_THREADS) {
  threads.new(sub {
		 if ($_[0]==1) {
		   LibXML::Element.new('root').appendChild($e);
		 }
		 1;
	       },$_);
}
$_.join for(threads.list);
# TEST
ok(1, "docfrag3");
}

=end TODO
