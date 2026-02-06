# ported from Perl XML::LibXML t/11memory.t
use v6;
use Test;
use LibXML;
use LibXML::Document;
use LibXML::Raw;
use Telemetry;

plan 19;
my $skip;

if $*KERNEL.name !~~ 'linux' {
    $skip = 'These tests only run on Linux';
}
elsif xml6_ref::total() < 0 {
    $skip = "please run '\$ make clean debug' to enable memory tests";
}

if $skip {
    skip-rest($skip);
    done-testing;
    exit(0);
}

constant TIMES-THROUGH = %*ENV<MEMORY_TIMES> || 5_000;

diag "running tests {TIMES-THROUGH} times";

class sax-null {...}

{

    pass 'Start.';

    # BASELINE
    check-mem(1);

    subtest 'make doc in sub', {
        mem-test {
            my LibXML::Document:D $doc = make-doc();
        }
    }

    subtest 'doc.Str', {
        # same test as the first one. if this still leaks, it's
        # our problem, otherwise it's perl :/
        mem-test {
            my LibXML::Document:D $doc = make-doc();
            my Str:D $ = $doc.Str
        }
    }

    subtest 'appendChild',{
        mem-test {
            my LibXML::Element $elem .= new("foo");
            my LibXML::Element $elem2 .= new("bar");
            $elem.appendChild($elem2);
        }
    }

    subtest 'set document element', {
        mem-test {
            my LibXML::Document:D $doc2 .= new();
            make-doc-elem( $doc2 );
        }
    }

    subtest 'multiple parsers', {
        LibXML.new(); # first parser

        mem-test {
            my LibXML $parser .= new();
        }
        pass 'Initialise multiple parsers.';
        # multiple parses
        mem-test {
            my LibXML $parser .= new();
            my $dom = $parser.parse: :string("<sometag>foo</sometag>");
        }
    }

    subtest 'multiple failing parses', {
        mem-test {
            my LibXML $parser .= new();
            try {
                my $dom = $parser.parse: :string("<sometag>foo</somtag>"); # Thats meant to be an error, btw!
            };
        }
    }

    subtest 'building custom docs', {
        my LibXML::Document $doc .= new();
        mem-test {
            my $elem = $doc.createElement('x');
            $doc.setDocumentElement($elem);

        }

        $doc = LibXML.createDocument;
        mem-test {
            make-doc2( $doc );
        }
    }

    my $dtdstr = 'samples/test.dtd'.IO.slurp;
    subtest 'DTD string parsing', {
        $dtdstr ~~ s:g/\r//;
        $dtdstr ~~ s/<[\r\n]>*$//;

        ok $dtdstr;

        mem-test {
            my LibXML::Dtd $dtd .= parse: :string($dtdstr);
        }
    }

    subtest 'DTD URI parsing', {
        mem-test {
            my LibXML::Dtd $dtd .= new('ignore', 'samples/test.dtd');
        }
    }

    subtest 'document validation', {
        my LibXML::Dtd $dtd .= parse: :string($dtdstr);
        my $xml;

        quietly {
            $xml = LibXML.parse: :file('samples/article_bad.xml');
        };

        mem-test {
            my $good;
            try {
                quietly { 
                    $good = $xml.is-valid($dtd);
                }
            };
        }

        diag "validate()";
        mem-test {
            try {
                quietly {
                    $xml.validate($dtd);
                }
            };
        }
        pass 'validate()';
        check-mem();
    }

    my $xml=q:to<dromeds.xml>;
    <?xml version="1.0" encoding="UTF-8"?>
    <dromedaries>
        <species name="Camel">
          <humps>1 or 2</humps>
          <disposition>Cranky</disposition>
        </species>
        <species name="Llama">
          <humps>1 (sort of)</humps>
          <disposition>Aloof</disposition>
        </species>
        <species name="Alpaca">
          <humps>(see Llama)</humps>
          <disposition>Friendly</disposition>
        </species>
    </dromedaries>
    dromeds.xml

    subtest 'first()', {
        my LibXML $parser .= new();
        my $doc  = $parser.parse: :string($xml);
        mem-test {
            my $elm  = $doc.getDocumentElement;
            my $node = $doc.first('/dromedaries/species');
        }
    }

    subtest 'parse() then first()', {
        my LibXML $parser .= new();
        todo "LibXML issue #85";
        mem-test {
            my $doc = $parser.parse: :string($xml);
            my $node = $doc.first('/dromedaries/species');
        }
    }

    subtest 'findnodes', {
        # my $str = "<foo><bar><foo/></bar></foo>";
        my $str = $xml;
        my $doc = LibXML.parse: :string( $str );
        mem-test {
            my @nodes = $doc.findnodes("/foo/bar/foo");
        }
    }

    subtest 'find', {
        my $str = "<foo><bar><foo/></bar></foo>";
        my $doc = LibXML.parse: :string( $str );
        mem-test {
            my $nodes = $doc.find("/foo/bar/foo");
        }
    }

#        {
#            diag "ENCODING TESTS";
#            my $string = "test � � is a test string to test iso encoding";
#            my $encstr = encodeToUTF8( "iso-8859-1" , $string );
#            for 1..TIMES-THROUGH {
#                my $str = encodeToUTF8( "iso-8859-1" , $string );
#            }
#            pass;
#            check-mem();

#            for 1..TIMES-THROUGH {
#                my $str = encodeToUTF8( "iso-8859-2" , "abc" );
#            }
#            pass;
#            check-mem();
#
#            for 1..TIMES-THROUGH {
#                my $str = decodeFromUTF8( "iso-8859-1" , $encstr );
#            }
#            pass;
#            check-mem();
#        }

    subtest 'namespace tests', {
        my $string = '<foo:bar xmlns:foo="bar"><foo:a/><foo:b/></foo:bar>';

        my LibXML::Document $doc .= parse: :string( $string );

        mem-test {
            my @ns = $doc.documentElement().getNamespaces();
            # warn "ns : " ~ .localname ~ "=>" ~ .href for @ns;
            my $prefix = .localname for @ns;
            my $name = $doc.documentElement.nodeName;
        }
    }

    subtest 'SAX parser', {
        my %xmlStrings = (
            "SIMPLE"      => '<xml1><xml2><xml3></xml3></xml2></xml1>',
            "SIMPLE TEXT" => '<xml1> <xml2>some text some text some text </xml2> </xml1>',
            "SIMPLE COMMENT" => '<xml1> <xml2> <!-- some text --> <!-- some text --> <!--some text--> </xml2> </xml1>',
            "SIMPLE CDATA" => '<xml1> <xml2><![CDATA[some text some text some text]]></xml2> </xml1>',
            "SIMPLE ATTRIBUTE" => '<xml1  attr0="value0"> <xml2 attr1="value1"></xml2> </xml1>',
            "NAMESPACES SIMPLE" => '<xm:xml1 xmlns:xm="foo"><xm:xml2/></xm:xml1>',
            "NAMESPACES ATTRIBUTE" => '<xm:xml1 xmlns:xm="foo"><xm:xml2 xm:foo="bar"/></xm:xml1>',
        );

        my sax-null $sax-handler .= new;
        my LibXML $parser .= new: :$sax-handler;

        check-mem();

        for %xmlStrings.keys.sort -> $key {
            diag $key;
            mem-test {
                my $doc = $parser.parse: :string( %xmlStrings{$key} );
            }
        }
        pass 'SAX PARSER';
    }

    subtest 'push parser', {

        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>", "<xml2><xml3></xml3></xml2>", "</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ", "<xml2>some text some text some text", " </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1", "> <xml2> <!", "-- some text --> <!-- some text --> <!--some text-", "-> </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ", "<xml2><!", "[CDATA[some text some text some text]", "]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ', 'attr0="value0"> <xml2 attr1="value1"></xml2>', ' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x', 'm="foo"><xm:xml2', '/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">', '<xm:xml2 xm:foo="bar"/></xm', ':xml1>'],
        );

        my sax-null $handler .= new;
        my LibXML $parser .= new;

        check-mem();
        for %xmlStrings.keys.sort -> $key {
            diag $key;
            mem-test {
                %xmlStrings{$key}.map: { $parser.push( $_ ) } ;
                my $doc = $parser.finish-push();
            }
        }
        # Cancelled TEST
        pass 'good pushed data';

        my %xmlBadStrings = (
            "SIMPLE"      => ["<xml1>"],
            "SIMPLE2"     => ["<xml1>", "</xml2>", "</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ", "some text some text some text", "</xml2>"],
            "SIMPLE CDATA"=> ["<xml1> ", "<!", "[CDATA[some text some text some text]", "</xml1>"],
            "SIMPLE JUNK" => ["<xml1/> ", "junk"],
        );

        for ( "SIMPLE", "SIMPLE2", "SIMPLE TEXT", "SIMPLE CDATA", "SIMPLE JUNK" ) -> $key {
            diag $key;
            mem-test {
                try {%xmlBadStrings{$key}.map: { $parser.push( $_ ) };};
                try {my $doc = $parser.finish-push();};
            }
        }
        pass 'bad pushed data';
    }

    subtest 'SAX push parser', {

        my sax-null $sax-handler .= new;
        my LibXML $parser .= new: :$sax-handler;
        check-mem();

        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>", "<xml2><xml3></xml3></xml2>", "</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ", "<xml2>some text some text some text", " </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1", "> <xml2> <!", "-- some text --> <!-- some text --> <!--some text-", "-> </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ", "<xml2><!", "[CDATA[some text some text some text]", "]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ', 'attr0="value0"> <xml2 attr1="value1"></xml2>', ' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x', 'm="foo"><xm:xml2', '/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">', '<xm:xml2 xm:foo="bar"/></xm', ':xml1>'],
        );

        for %xmlStrings.keys.sort -> $key {
            diag $key;
            mem-test {
                try { %xmlStrings{$key}.map: { $parser.push( $_ ) };};
                try {my $doc = $parser.finish-push();};
            }
        }
        pass 'SAX PUSH PARSER';

        subtest 'bad pushed data', {

            my %xmlBadStrings = (
                "SIMPLE "      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>", "</xml2>", "</xml1>"],
                "SIMPLE TEXT"  => ["<xml1> ", "some text some text some text", "</xml2>"],
                "SIMPLE CDATA" => ["<xml1> ", "<!", "[CDATA[some text some text some text]", "</xml1>"],
                "SIMPLE JUNK"  => ["<xml1/> ", "junk"],
            );

            for %xmlBadStrings.keys.sort -> $key {
                diag $key;
                mem-test {
                    try { %xmlBadStrings{$key}.map: { $parser.push( $_ ) };};
                    try {my $doc = $parser.finish-push();};
                }

                check-mem();
            }
            pass 'BAD PUSHED DATA';
        }
    }
}

summarise-mem();

sub processMessage($msg, $xpath) {
}

sub make-doc {
    # code taken from an AxKit XSP generated page
    my $document = LibXML::Document.createDocument("1.0", "UTF-8");
    # warn("document: $document\n");
    my $parent;

    {
        my $elem = $document.createElement('p');
        $document.setDocumentElement($elem);
        $parent = $elem;
    }

    $parent.setAttribute("xmlns:" ~ 'param', 'http://axkit.org/XSP/param');

    {
        my $elem = $document.createElementNS('http://axkit.org/XSP/param', 'param:foo',);
        $parent.appendChild($elem);
        $parent = $elem;
    }

    $parent .= parentNode;
    $parent .= parentNode;

    return $document
}

sub make-doc2($docA) {
    my LibXML::Document $docB .= new;
    my $e1   = $docB.createElement( "A" );
    my $e2   = $docB.createElement( "B" );
    $e1.appendChild( $e2 );
    $docA.setDocumentElement( $e1 );
}

our $units;

sub check-mem($initialise?) {
    # Log Memory Usage
    my %mem;
  ##  $*VM.request-garbage-collection;
    given '/proc/self/status'.IO.open -> $FH {
        for $FH.lines {
            if (/^VmSize.*?(\d+)\W*(\w+)$/) {
                %mem<Total> = $0.Int;
                $units = $1;
            }
        }
        $FH.close;

        %mem<Resident> = T.max-rss;
        
        $LibXML::TOTALMEM //= 0;

        if ($initialise) {
            $LibXML::STARTMEM = %mem<Total>;
        }

        if ($LibXML::TOTALMEM != %mem<Total>) {
            note("Change! : ", %mem<Total> - $LibXML::TOTALMEM, " $units") unless $initialise;
            $LibXML::TOTALMEM = %mem<Total>;
        }

        my $live-objects = xml6_ref::current();
        $LibXML::TOTALOBJS += $live-objects;
        $LibXML::MEMCHECKS++;

        note("Mem Total: %mem<Total> $units, Resident: %mem<Resident> $units, Objects: $live-objects");
    }
}

sub summarise-mem() {
    $*VM.request-garbage-collection;
    my $total-objects = xml6_ref::total() || 1;
    my $lost-objects = xml6_ref::current();
    my $lost-pcnt = sprintf("%.02f", 100 * $lost-objects / $total-objects);

    note("Total Mem Increase:{$LibXML::TOTALMEM - $LibXML::STARTMEM} $units, Avg-Objects:{$LibXML::TOTALOBJS div $LibXML::MEMCHECKS}, Lost:$lost-objects Objects ($lost-pcnt\%)");
}

sub mem-test(&test) {
    my $live-objects = xml6_ref::current;
    for 1..TIMES-THROUGH {
        &test();
    }
    check-mem();
    my $live-objects2 = xml6_ref::current;
    ok ($live-objects2 - $live-objects < 500), "no major memory leaks";
}

# some tests for document fragments
sub make-doc-elem($doc) {
    my LibXML::Document $dd .= new();
    my $node1 = $doc.createElement('test1');
    my $node2 = $doc.createElement('test2');
    $doc.setDocumentElement( $node1 );
}

use LibXML::SAX::Handler::SAX2;

class sax-null
    is LibXML::SAX::Handler::SAX2 {

    method finish($doc) { $doc }
}
