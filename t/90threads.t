use v6;
use Test;
plan 23;
use LibXML;
use LibXML::Attr;
use LibXML::Document;
use LibXML::Element;
use LibXML::RelaxNG;
use LibXML::Parser;
use LibXML::InputCallback;

INIT my \MAX_THREADS = %*ENV<MAX_THREADS> || 10;
INIT my \MAX_LOOP = %*ENV<MAX_LOOP> || 50;

my LibXML:D $p .= new();

sub blat(&r, :$n = MAX_THREADS) {
    (^$n).race(:batch(1)).map(&r);
}

sub trundle(&r, :$n = MAX_THREADS) {
    (^$n).map(&r);
}

subtest 'dtd' => {
    plan 2;
    my LibXML::Document $doc .= parse: :file<samples/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my @ok = (1..MAX_LOOP).map: {
        my @k = blat {$doc.is-valid && $dtd.is-valid($doc) && $doc.is-valid($dtd) };
        @k.all.so;
    }
    ok @ok.all.so;
    my LibXML::Document $bad .= parse: :string('<bar/>');

    @ok = (1..MAX_LOOP).map: {
        my @k = blat { ! ($dtd.is-valid($bad) || $bad.is-valid($dtd)) }
        @k.all.so;
    }
        
    ok @ok.all.so;
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

subtest 'parse strings', {
    my X::LibXML::Parser:D @err = blat { try { LibXML.parse: :string('foo'); } for 1..100; $! };
    is @err.elems, MAX_THREADS, 'parse errors';
}

subtest 'create element/attribute', {
    my LibXML::Document $doc .= new;
    $doc.setDocumentElement($doc.createElement('root'));
    $doc.getDocumentElement.setAttribute('foo','bar');

    my LibXML::Element:D @roots = blat {
        my LibXML::Element:D @r = blat {
            $doc.getDocumentElement;
        }
        @r.pick;
    };
    is +@roots, MAX_THREADS, 'document roots';
    is @roots>>.unique-key.unique.elems, 1, 'document root reduction';
}

subtest 'operating on different documents without lock', {
    my LibXML::Document:D @docs = blat {
        my LibXML::Document $doc .= new;
        $doc.setDocumentElement($doc.createElement('root'));
        $doc.getDocumentElement.setAttribute('foo','bar');
        $doc
    }
    is @docs.elems, MAX_THREADS, 'document roots';
    is @docs.unique.elems, MAX_THREADS, "unique documents don't reduce";

    my Str:D @values = blat {
        my LibXML::Document:D $doc = @docs[$_];
        my Str:D @values = await (^20).map: { start {
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

subtest 'operating on the same document with a lock', {
    my LibXML::Document $doc .= new;
    my LibXML::Document:D @docs = blat {
        for 1..24 {
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

subtest 'access leaf nodes', {
    my LibXML::Element @nodes;
    {
        my $doc = $p.parse: :string($xml);
        @nodes = blat { $doc.documentElement[0][0] }
    }
    is @nodes.elems, MAX_THREADS, 'document leaf nodes';
    is @nodes.map(*.unique-key).unique.elems, 1, 'document leaf nodes reduction';
    is @nodes.pick.Str, '<leaf/>', 'sampled node';
}

subtest 'multiple documents', {
    my LibXML::Document @docs = blat { $p.parse: :string($xml) };
    is @docs.elems, MAX_THREADS, 'document leaf nodes';
    is @docs.map(*.unique-key).unique.elems, MAX_THREADS, 'document leaf nodes reduced by unique keys';
    is @docs.map(*.Str).unique.elems, 1, 'document leaf nodes reduced by content';
}

subtest 'input callbacks, global', {
    my atomicint $open-calls = 0;
    my LibXML::InputCallback() $callbacks = (
                -> $ { $open-calls⚛++; True },
                -> $file { $file.IO.open(:r) },
                -> $fh, $n { $fh.read($n); },
                -> $fh { $fh.close },
    );
    temp LibXML::Config.input-callbacks = $callbacks;
    for (^MAX_LOOP) {
        my LibXML::Document:D @ = blat {
            my LibXML $parser .= new;
            $parser.parse: :location<samples/dromeds.xml>;
        }
    }
    is $open-calls, MAX_LOOP * MAX_THREADS, 'input callbacks';
}

subtest 'input callbacks, local', {
    my Int $open-calls = 0;
    temp LibXML::Config.parser-locking = True;
    for (^MAX_LOOP) {
        my atomicint $local-open-calls = 0;
        my LibXML::InputCallback() $callbacks = (
            -> $ { $local-open-calls⚛++; True },
            -> $file { $file.IO.open(:r) },
            -> $fh, $n { $fh.read($n); },
            -> $fh { $fh.close },
        );
        my LibXML $parser .= new;
        $parser.input-callbacks = $callbacks;
        my LibXML::Document:D @ = blat {
            $parser.parse: :location<samples/dromeds.xml>;
        }
        $open-calls += $local-open-calls;
    }
    is $open-calls, MAX_LOOP * MAX_THREADS, 'input callbacks';
}

subtest 'parsing with errors', {
    my $xml_bad = q:to<EOF>;
    <?xml version="1.0" encoding="utf-8"?>
    <root><node><leaf/></root>
    EOF

    my X::LibXML::Parser:D @err = blat { try { my $x = $p.parse: :string($xml_bad)} for 1..100; $!; }
    is @err.elems, MAX_THREADS, 'parse errors';
}

subtest 'parsing of invalid documents', {
    my $xml_invalid = q:to<EOF>;
    <?xml version="1.0" encoding="utf-8"?>
    <!DOCTYPE root [
    <!ELEMENT root EMPTY>
    ]>
    <root><something/></root>
    EOF

  my LibXML::Document:D @docs = blat {
      my $x = $p.parse: :string($xml_invalid);
      die if $x.is-valid;
      try { $x.validate };
      die unless $!;
      $x;
  }
  is @docs.elems, MAX_THREADS, 'well-formed, but invalid documents';
}

subtest 'relaxNG schema validation', {
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

    my @ok = blat {
        my $ok = True;
        for 1..MAX_LOOP {
	    my $x = $p.parse: :string($xml);
	    try { LibXML::RelaxNG.new( string => $rngschema ).validate( $x ) };
            $ok = False without $!;
        }
	$ok;
    }
    ok @ok.all.so, "test RNG validation errors thread safe sanity";
}

subtest 'XML schema validation', {
    my $xsdschema = q:to<EOF>;
    <?xml version="1.0"?>
    <xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <xsd:element name="root">
        <xsd:attribute name="partNum" type="SKU" use="required"/>
      </xsd:element>
    </xsd:schema>
    EOF

    my @ok = blat {
        my $ok = True;
        for 1..MAX_LOOP {
	    my $x = $p.parse: :string($xml);
	    try { LibXML::Schema.new( string => $xsdschema ).validate( $x ) };
            $ok = False without $!;
        }
        $ok;
    }
    ok @ok.all.so, "test Schema validation errors thread safe sanity";
}

sub use_dom($d) {
    my @nodes = $d.getElementsByTagName("files");
    for @nodes {
	my $tag = .tag;
    }
    die unless @nodes[0].tag eq 'files';
}

my $bigfile = "etc/libxml2-api.xml";
my $string = $bigfile.IO.slurp;
ok $string , 'bigfile was slurped fine.';

subtest 'dom access', {
    my @ok = blat { my $dom = do { $p.parse: :$string }; use_dom($dom) for 1..5; True};
     ok @ok.all.so, 'Joined all threads.';
}

subtest 'check parsing', {
    use LibXML::SAX::Handler::SAX2;
    class MyHandler is LibXML::SAX::Handler::SAX2 {

    }

    use LibXML::SAX;
    my LibXML::SAX:D $p .= new(
	:sax-handler(MyHandler.new),
    );
    my @ok = blat { $p.parse: :$string for 1..5; True; }
    ok @ok.all.so, 'After LibXML::SAX - join.';

    $p .= new(
	:sax-handler(MyHandler.new),
    );
    $p.parse: :chunk($string);
    $p.parse: :terminate;

    @ok = blat {
        use_dom($p.parse: :chunk($string), :terminate);
        True;
    }
    ok @ok.all.so, 'LibXML thread.';

    $p .= new();
    # parse a big file using the same parser
    @ok = True;
    unless $*DISTRO.is-win {
        @ok = blat {
            my IO::Handle $io = $bigfile.IO.open(:r);
            $p.parse: :$io;
            $io.close;
            True;
        }
    }

    ok @ok.all.so, 'threads.join after opening bigfile.';
}

subtest 'create elements', {
    my @ok = blat { my @n = map {LibXML::Element.new('bar'~$_)}, 1..100; True }
    ok @ok.all.so;
}

# ported from Perl

subtest 'docfrag', {
    my LibXML::Element $e .= new('foo');
    my @ok = blat {
        my LibXML::Document $d .= new();
        $d.setDocumentElement($d.createElement('root'));
        $e.protect: { $d.documentElement.appendChild($e); }
        True;
    }
    ok @ok.all.so;
}

subtest 'docfrag2', {
    my LibXML::Element $e .= new('foo');
    my LibXML::Document $d .= new();
    $d.setDocumentElement: $d.createElement('root');
    my @ok = blat {
	$e.protect: {$d.protect: { $d.documentElement.appendChild($e); }}
        True;
    }
    ok @ok.all.so;
}

subtest 'docfrag3', {
    my LibXML::Element $e .= new('foo');
    my @ok = blat {
	$e.protect: { LibXML::Element.new('root').appendChild($e); }
        True;
    }
    ok @ok.all.so;
}

subtest 'xinclude', {
    my $file = 'test/xinclude/test.xml';
    my LibXML $parser .= new;
    $parser.expand-xinclude = True;
    $parser.expand-entities = True;
    my @ok = blat { $parser.parse(:$file) for 1..10; True }
    ok @ok.all.so;
}

subtest 'xpath', {
    my @sym = <xx docbParserInputPtr docbParserCtxt docbParserCtxtPtr docbParserInput docbDocPtr>;
    my LibXML::Document $doc .= parse: :$string;
    my @ok = (1..MAX_LOOP).map: {
        my @all = trundle -> $n {
            my $m = $n % 5 + 1;
            my $elem = $doc.first("/api/files/file[1]/exports[$m]");
            $elem.getAttribute('symbol') eq @sym[$m];
        };
    }
    ok @ok.all.so;
}
