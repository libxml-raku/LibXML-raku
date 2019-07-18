use v6;
use Test;
use LibXML;
use LibXML::Document;
use LibXML::RelaxNG;
constant MAX_THREADS = 10;
constant MAX_LOOP = 50;
# use constant PLAN => 24;

# TEST
ok(1, 'Loaded');

my LibXML $p .= new();
# TEST
ok($p.defined, 'Parser initted.');

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
  my LibXML::Document $bad .= parse: :string('<bad/>');
  my LibXML::RelaxNG @schemas = (0 ..^ MAX_THREADS).race.map: {
        LibXML::RelaxNG.new(string=>$grammar);
    }
  my @good = (0 ..^ MAX_THREADS).race.map: {
      @schemas[$_].is-valid($good);
    }
  my @bad = (0 ..^ MAX_THREADS).race.map: {
      @schemas[$_].is-valid($bad);
    }

  is +@schemas, 10, 'relaxng schemas';
  is-deeply (+@good, [@good.unique]), (10, [True]), 'relax-ng valid';
  is-deeply (+@bad, [@bad.unique]), (10, [False]), 'relax-ng invalid';
}

skip "port remaining tests";
done-testing();
=begin TODO

{
    eval { LibXML.new.parse_string('foo') };
    for(1..40) {
        threads.new(sub { eval { LibXML.new.parse_string('foo') } for(1..1000);  1; });
    }
    $_.join for(threads.list);
    # TEST
    ok(1, "XML error\n");
}


{
  my $doc=LibXML::Document.new;
  $doc.setDocumentElement($doc.createElement('root'));
  $doc.getDocumentElement.setAttribute('foo','bar');
#   threads.new(sub {
# 		 for (1..100000) {
# 		   # a dictionary of $doc
# 		   my $el =$doc.createElement('foo'.$_);
# 		   $el.setAttribute('foo','bar');
# 		 }
# 		 return;
# 	       });
  for my $t_no (1..40) {
    threads.new(sub {
                   for (1..1000) {
                     $doc.getDocumentElement;
                   }
                   return;
                 });
  }
  $_.join for(threads.list);
}
# TEST
ok(1, "accessing document elements without lock");
{
  my @docs=map {
    my $doc = LibXML::Document.new;
    $doc.setDocumentElement($doc.createElement('root'));
    $doc.getDocumentElement.setAttribute('foo','bar');
    $doc } 1..40;
  for my $t_no (1..40) {
    threads.new(sub {
		   my $doc=$docs[$t_no-1];
		   for (1..10000) {
		     # a dictionary of $doc
		     my $el =$doc.createElement('foo'.$_);
		     $el.setAttribute('foo','bar');
                     $doc.getDocumentElement.getAttribute('foo');
		     $el.getAttribute('foo');
		   }
		   return;
		 });
  }
  $_.join for(threads.list);
}
# TEST
ok(1, "operating on different documents without lock\n");

# operating on the same document with a lock
{
  my $lock : shared;
  my $doc=LibXML::Document.new;
  for my $t_no (1..40) {
    threads.new(sub {
                   for (1..10000) {
		     lock $lock; # must lock since libxml2 uses
		                 # a dictionary of $doc
                     my $el =$doc.createElement('foo');
                     $el.setAttribute('foo','bar');
		     $el.getAttribute('foo');
                   }
                   return;
                 });
  }
  $_.join for(threads.list);
}


my $xml = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<root><node><leaf/></node></root>
EOF

{
my $doc = $p.parse_string( $xml );
for(1..MAX_THREADS)
{
	threads.new(sub {});
}
$_.join for(threads.list);
}
# TEST
ok(1, "Spawn threads with a document in scope");


{
my $waitfor : shared;
{
lock $waitfor;
my $doc = $p.parse_string($xml);
for(1..MAX_THREADS)
{
	threads.new(sub { lock $waitfor; $doc.toString; });
}
}
$_.join for(threads.list);
# TEST
ok(1, "Spawn threads that use document that has gone out of scope from where it was created");
}

{
for(1..MAX_THREADS)
{
	threads.new(sub { $p.parse_string($xml) for 1..MAX_LOOP; 1; });
}
$_.join for(threads.list);
# TEST
ok(1, "Parse a correct XML document");
}

my $xml_bad = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<root><node><leaf/></root>
EOF


{
for(1..MAX_THREADS)
{
	threads.new(sub { eval { my $x = $p.parse_string($xml_bad)} for(1..MAX_LOOP); 1; });
}
$_.join for(threads.list);
# TEST
ok(1, "Parse a bad XML document\n");
}


my $xml_invalid = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE root [
<!ELEMENT root EMPTY>
]>
<root><something/></root>
EOF

{
for(1..MAX_THREADS)
{
  threads.new(sub {
		 for (1..MAX_LOOP) {
		   my $x = $p.parse_string($xml_invalid);
		   die if $x.is_valid;
		   eval { $x.validate };
		   die unless $@;
		 }
               1;
	       });
}
$_.join for(threads.list);
# TEST
ok(1, "Parse an invalid XML document");
}

my $rngschema = <<EOF;
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
for(1..MAX_THREADS)
{
  threads.new(
    sub {
      for (1..MAX_LOOP) {
	my $x = $p.parse_string($xml);
	eval { LibXML::RelaxNG.new( string => $rngschema ).validate( $x ) };
	die unless $@;
      }; 1;
    });
}
$_.join for(threads.list);
# TEST
ok(1, "test RNG validation errors are thread safe");
}

my $xsdschema = <<EOF;
<?xml version="1.0"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:element name="root">
    <xsd:attribute name="partNum" type="SKU" use="required"/>
  </xsd:element>
</xsd:schema>
EOF

{
for(1..MAX_THREADS)
{
  threads.new(
    sub {
      for (1..MAX_LOOP) {
 	my $x = $p.parse_string($xml);
 	eval { LibXML::Schema.new( string => $xsdschema ).validate( $x ) };
 	die unless $@;
      }; 1;
    });
}
$_.join for(threads.list);
# TEST
ok(1, "test Schema validation errors are thread safe");
}

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
