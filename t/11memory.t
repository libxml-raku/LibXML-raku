use v6;
use Test;
use LibXML;
use LibXML::Raw;
use Telemetry;

plan 17;
my $skip;

if !( %*ENV<AUTHOR_TESTING> or %*ENV<RELEASE_TESTING> ) {
    $skip = "These tests are for authors only!";
}
elsif $*KERNEL.name !~~ 'linux'
{
    $skip = 'These tests only run on Linux';
}
elsif ! %*ENV<MEMORY_TEST>
{
    $skip = "developers only (set MEMORY_TEST=1 to run these tests)";
}
elsif LibXML::Raw::ref-total() < 0 {
    $skip = "please run '\$ make clean debug' to enable debugging";
}

if $skip {
    skip-rest($skip);
    done-testing;
    exit(0);
}

constant TIMES_THROUGH = %*ENV<MEMORY_TIMES> || 5_000;

diag "running tests {TIMES_THROUGH} times";

class sax_null {...}

{

    pass('Start.');

    # BASELINE
    check_mem(1);

    subtest 'make doc in sub', {
        my $doc = make_doc();
        ok $doc.defined;
        ok $doc.Str.defined, 'Str()';
        check_mem();
    }

    subtest 'make doc in sub II', {
        # same test as the first one. if this still leaks, it's
        # our problem, otherwise it's perl :/
        my $doc = make_doc();
        $doc.defined;

        ok $doc.Str.defined, 'Str()';
        check_mem();
    }

    subtest 'appendChild',{
        my $elem = LibXML::Element.new("foo");
        my $elem2= LibXML::Element.new("bar");
        $elem.appendChild($elem2);
        ok $elem.Str;
        check_mem();
    }

    subtest 'set document element', {
        my $doc2 = LibXML::Document.new();
        make_doc_elem( $doc2 );
        ok $doc2.defined;
        ok $doc2.documentElement.defined, 'documentElement';
        check_mem();
    }

    subtest 'multiple parsers', {
        LibXML.new(); # first parser
        check_mem(1);

        for 1..TIMES_THROUGH {
            my $parser = LibXML.new();
        }
        pass 'Initialise multiple parsers.';
        check_mem();
        # multiple parses
        for 1..TIMES_THROUGH {
            my $parser = LibXML.new();
            my $dom = $parser.parse: :string("<sometag>foo</sometag>");
        }
        pass('multiple parses');

        check_mem();
    }

    subtest 'multiple failing parses', {
        for 1..TIMES_THROUGH {
            # warn("$_\n") unless $_ % 100;
            my $parser = LibXML.new();
            try {
                my $dom = $parser.parse: :string("<sometag>foo</somtag>"); # Thats meant to be an error, btw!
            };
        }
        pass('Multiple failures.');

        check_mem();
    }

    subtest 'building custom docs', {
        my $doc = LibXML::Document.new();
        for 1..TIMES_THROUGH        {
            my $elem = $doc.createElement('x');
            $doc.setDocumentElement($elem);

        }
        pass('customDocs');
        check_mem();

        {
            my $doc = LibXML.createDocument;
            for 1..TIMES_THROUGH        {
                make_doc2( $doc );
            }
        }
        pass('customDocs No. 2');
        check_mem();
    }

    my $dtdstr = 'samples/test.dtd'.IO.slurp;
    subtest 'DTD string parsing', {
        $dtdstr ~~ s:g/\r//;
        $dtdstr ~~ s/<[\r\n]>*$//;

        ok $dtdstr;

        for 1..TIMES_THROUGH {
            my $dtd = LibXML::Dtd.parse: :string($dtdstr);
        }
        pass('after dtdstr');
        check_mem();
    }

    subtest 'DTD URI parsing', {
        for 1..TIMES_THROUGH {
            my $dtd = LibXML::Dtd.new('ignore', 'samples/test.dtd');
        }
        pass('after URI parsing.');
        check_mem();
    }

    subtest 'document validation', {
        # is_valid()
        my $dtd = LibXML::Dtd.parse: :string($dtdstr);
        my $xml;
        try {
            quietly {
                $xml = LibXML.parse: :file('samples/article_bad.xml');
            }
        };
        for 1..TIMES_THROUGH {
            my $good;
            try {
                quietly { 
                    $good = $xml.is_valid($dtd);
                }
            };
        }
        pass('is_valid()');
        check_mem();

        print "# validate() \n";
        for 1..TIMES_THROUGH {
            try {
                quietly {
                    $xml.validate($dtd);
                }
            };
        }
        pass('validate()');
        check_mem();
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

    subtest 'findnodes', {
        # my $str = "<foo><bar><foo/></bar></foo>";
        my $str = $xml;
        my $doc = LibXML.parse: :string( $str );
        for 1..TIMES_THROUGH {
            processMessage($xml, '/dromedaries/species' );
            my @nodes = $doc.findnodes("/foo/bar/foo");
        }
        pass('after processMessage');
        check_mem();

    }

    subtest 'find', {
        my $str = "<foo><bar><foo/></bar></foo>";
        my $doc = LibXML.parse: :string( $str );
        for 1..TIMES_THROUGH {
            my $nodes = $doc.find("/foo/bar/foo");
        }
        pass('.find.');
        check_mem();

    }

#        {
#            print "# ENCODING TESTS \n";
#            my $string = "test � � is a test string to test iso encoding";
#            my $encstr = encodeToUTF8( "iso-8859-1" , $string );
#            for 1..TIMES_THROUGH {
#                my $str = encodeToUTF8( "iso-8859-1" , $string );
#            }
#            ok(1);
#            check_mem();

#            for 1..TIMES_THROUGH {
#                my $str = encodeToUTF8( "iso-8859-2" , "abc" );
#            }
#            ok(1);
#            check_mem();
#
#            for 1..TIMES_THROUGH {
#                my $str = decodeFromUTF8( "iso-8859-1" , $encstr );
#            }
#            ok(1);
#            check_mem();
#        }

    subtest 'namespace tests', {
        my $string = '<foo:bar xmlns:foo="bar"><foo:a/><foo:b/></foo:bar>';

        my $doc = LibXML.new().parse: :string( $string );

        for 1..TIMES_THROUGH {
            my @ns = $doc.documentElement().getNamespaces();
            # warn "ns : " ~ .localname ~ "=>" ~ .href for @ns;
            my $prefix = .localname for @ns;
            my $name = $doc.documentElement.nodeName;
        }
        check_mem();
        pass('namespace tests.');
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

        my $sax-handler = sax_null.new;
        my $parser  = LibXML.new: :$sax-handler;

        check_mem();

        for %xmlStrings.keys.sort -> $key  {
            print "# $key \n";
            for 1..TIMES_THROUGH {
                my $doc = $parser.parse: :string( %xmlStrings{$key} );
            }

            check_mem();
        }
        ok (1, 'SAX PARSER');
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

        my $handler = sax_null.new;
        my $parser  = LibXML.new;

        check_mem();
        for %xmlStrings.keys.sort -> $key  {
            print "# $key \n";
            for 1..TIMES_THROUGH {
                %xmlStrings{$key}.map: { $parser.push( $_ ) } ;
                my $doc = $parser.finish-push();
            }

            check_mem();
        }
        # Cancelled TEST
        pass('good pushed data');

        my %xmlBadStrings = (
            "SIMPLE"      => ["<xml1>"],
            "SIMPLE2"     => ["<xml1>", "</xml2>", "</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ", "some text some text some text", "</xml2>"],
            "SIMPLE CDATA"=> ["<xml1> ", "<!", "[CDATA[some text some text some text]", "</xml1>"],
            "SIMPLE JUNK" => ["<xml1/> ", "junk"],
        );

        for ( "SIMPLE", "SIMPLE2", "SIMPLE TEXT", "SIMPLE CDATA", "SIMPLE JUNK" ) -> $key  {
            print "# $key \n";
            for 1..TIMES_THROUGH {
                try {%xmlBadStrings{$key}.map: { $parser.push( $_ ) };};
                try {my $doc = $parser.finish-push();};
            }

            check_mem();
        }
        pass('bad pushed data');
    }

    subtest 'SAX push parser', {

        my $sax-handler = sax_null.new;
        my $parser  = LibXML.new: :$sax-handler;
        check_mem();

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
            print "# $key \n";
            for 1..TIMES_THROUGH {
                try { %xmlStrings{$key}.map: { $parser.push( $_ ) };};
                try {my $doc = $parser.finish-push();};
            }

            check_mem();
        }
        pass('SAX PUSH PARSER');

        subtest 'bad pushed data', {

            my %xmlBadStrings = (
                "SIMPLE "      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>", "</xml2>", "</xml1>"],
                "SIMPLE TEXT"  => ["<xml1> ", "some text some text some text", "</xml2>"],
                "SIMPLE CDATA" => ["<xml1> ", "<!", "[CDATA[some text some text some text]", "</xml1>"],
                "SIMPLE JUNK"  => ["<xml1/> ", "junk"],
            );

            for %xmlBadStrings.keys.sort -> $key  {
                print "# $key \n";
                for 1..TIMES_THROUGH {
                    try { %xmlBadStrings{$key}.map: { $parser.push( $_ ) };};
                    try {my $doc = $parser.finish-push();};
                }

                check_mem();
            }
            pass('BAD PUSHED DATA');
        }
    }
}

summarise_mem();

sub processMessage($msg, $xpath) {
      my $parser = LibXML.new();

      my $doc  = $parser.parse: :string($msg);
      my $elm  = $doc.getDocumentElement;
      my $node = $doc.first($xpath);
      my $text = $node.to-literal;
}

sub make_doc {
    # code taken from an AxKit XSP generated page
    my $document = LibXML::Document.createDocument("1.0", "UTF-8");
    # warn("document: $document\n");
    my ($parent);

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

    $parent = $parent.parentNode;
    # warn("parent now: $parent\n");
    $parent = $parent.parentNode;
    # warn("parent now: $parent\n");

    return $document
}

sub make_doc2($docA) {
    my $docB = LibXML::Document.new;
    my $e1   = $docB.createElement( "A" );
    my $e2   = $docB.createElement( "B" );
    $e1.appendChild( $e2 );
    $docA.setDocumentElement( $e1 );
}

our $units;

sub check_mem($initialise?) {
    # Log Memory Usage
    my %mem;
    $*VM.request-garbage-collection;
    given '/proc/self/status'.IO.open -> $FH {
        for $FH.lines {
            if (/^VmSize.*?(\d+)\W*(\w+)$/) {
                %mem<Total> = $0;
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

        my $live-objects = LibXML::Raw::ref-current;

        note("# Mem Total: %mem<Total> $units, Resident: %mem<Resident> $units, Objects: $live-objects");
    }
}

sub summarise_mem() {
    $*VM.request-garbage-collection;
    my $total-objects = LibXML::Raw::ref-total() || 1;
    my $lost-objects = LibXML::Raw::ref-current();
    my $lost-pcnt = sprintf("%.02f", 100 * $lost-objects / $total-objects);

    note("# Total Mem Increase: {$LibXML::TOTALMEM - $LibXML::STARTMEM} $units, Lost: $lost-objects/$total-objects Objects ($lost-pcnt\%)");
}

# some tests for document fragments
sub make_doc_elem($doc) {
    my $dd = LibXML::Document.new();
    my $node1 = $doc.createElement('test1');
    my $node2 = $doc.createElement('test2');
    $doc.setDocumentElement( $node1 );
}

use LibXML::SAX::Builder :sax-cb;
use LibXML::SAX::Handler::SAX2;

class sax_null
    is LibXML::SAX::Handler::SAX2 {

    method finish($doc) { $doc }
}
