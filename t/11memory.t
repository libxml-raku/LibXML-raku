use v6;
use Test;

plan 25;
my $skip;

if !( %*ENV<AUTHOR_TESTING> or %*ENV<RELEASE_TESTING> ) {
    $skip = "These tests are for authors only!";
}
elsif $*KERNEL.name !~~ 'linux'|'cygwin'
{
    $skip = 'These tests only run on Linux and Cygwin.';
}
elsif ! %*ENV<MEMORY_TEST>
{
    $skip = "developers only (set MEMORY_TEST=1 to run these tests)";
}

if $skip {
    skip-rest($skip);
    done-testing;
    exit(0);
}

#todo: use Telemetry?

constant TIMES_THROUGH = %*ENV<MEMORY_TIMES> || 5_000;

diag "running tests {TIMES_THROUGH} times";

class sax_null {...}

use LibXML;
{

        pass('Start.');

        # BASELINE
        check_mem(1);

        # MAKE DOC IN SUB
        {
            my $doc = make_doc();
            ok($doc, 'Make doc in sub 1.');
            ok($doc.Str.defined, 'Make doc in sub 1 - Str().');
        }
        check_mem();
        # MAKE DOC IN SUB II
        # same test as the first one. if this still leaks, it's
        # our problem, otherwise it's perl :/
        {
            my $doc = make_doc();
            ok($doc, 'Make doc in sub 2 - doc.');

            ok($doc.Str.defined, 'Make doc in sub 2 - Str()');
        }
        check_mem();

        {
            my $elem = LibXML::Element.new("foo");
            my $elem2= LibXML::Element.new("bar");
            $elem.appendChild($elem2);
            ok( $elem.Str, 'appendChild.' );
        }
        check_mem();

        # SET DOCUMENT ELEMENT
        {
            my $doc2 = LibXML::Document.new();
            make_doc_elem( $doc2 );
            ok( $doc2, 'SetDocElem');
            ok( $doc2.documentElement, 'SetDocElem documentElement.' );
        }
        check_mem();

        # multiple parsers:
        # MULTIPLE PARSERS
        LibXML.new(); # first parser
        check_mem(1);

        for (1..TIMES_THROUGH) {
            my $parser = LibXML.new();
        }
        pass('Initialise multiple parsers.');

        check_mem();
        # multiple parses
        for (1..TIMES_THROUGH) {
            my $parser = LibXML.new();
            my $dom = $parser.parse: :string("<sometag>foo</sometag>");
        }
        pass('multiple parses');

        check_mem();

        # multiple failing parses
        # MULTIPLE FAILURES
        for (1..TIMES_THROUGH) {
            # warn("$_\n") unless $_ % 100;
            my $parser = LibXML.new();
            try {
                my $dom = $parser.parse: :string("<sometag>foo</somtag>"); # Thats meant to be an error, btw!
            };
        }
        pass('Multiple failures.');

        check_mem();

        # building custom docs
        my $doc = LibXML::Document.new();
        for (1..TIMES_THROUGH)        {
            my $elem = $doc.createElement('x');

            $doc.setDocumentElement($elem);

        }
        pass('customDocs');
        check_mem();

        {
            my $doc = LibXML.createDocument;
            for (1..TIMES_THROUGH)        {
                make_doc2( $doc );
            }
        }
        pass('customDocs No. 2');
        check_mem();

        # DTD string parsing

        my $dtdstr = 'example/test.dtd'.IO.slurp;
        $dtdstr ~~ s:g/\r//;
        $dtdstr ~~ s/<[\r\n]>*$//;


        ok($dtdstr, '$dtdstr');

        for ( 1..TIMES_THROUGH ) {
            my $dtd = LibXML::Dtd.parse: :string($dtdstr);
        }
        pass('after dtdstr');
        check_mem();

        # DTD URI parsing
        # parse a DTD from a SYSTEM ID
        for ( 1..TIMES_THROUGH ) {
            my $dtd = LibXML::Dtd.new('ignore', 'example/test.dtd');
        }
        pass('DTD URI parsing.');
        check_mem();

        # Document validation
        {
            # is_valid()
            my $dtd = LibXML::Dtd.parse: :string($dtdstr);
            my $xml;
            try {
                quietly {
                    $xml = LibXML.parse: :file('example/article_bad.xml');
                }
            };
            for ( 1..TIMES_THROUGH ) {
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
            for ( 1..TIMES_THROUGH ) {
                try {
                    quietly {
                        $xml.validate($dtd);
                    }
                };
            }
            pass('validate()');
            check_mem();

        }

        print "# FIND NODES \n";
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

        {
            # my $str = "<foo><bar><foo/></bar></foo>";
            my $str = $xml;
            my $doc = LibXML.parse: :string( $str );
            for ( 1..TIMES_THROUGH ) {
                processMessage($xml, '/dromedaries/species' );
                my @nodes = $doc.findnodes("/foo/bar/foo");
            }
            pass('after processMessage');
            check_mem();

        }

        {
            my $str = "<foo><bar><foo/></bar></foo>";
            my $doc = LibXML.parse: :string( $str );
            for ( 1..TIMES_THROUGH ) {
                my $nodes = $doc.find("/foo/bar/foo");
            }
            pass('.find.');
            check_mem();

        }

#        {
#            print "# ENCODING TESTS \n";
#            my $string = "test � � is a test string to test iso encoding";
#            my $encstr = encodeToUTF8( "iso-8859-1" , $string );
#            for ( 1..TIMES_THROUGH ) {
#                my $str = encodeToUTF8( "iso-8859-1" , $string );
#            }
#            ok(1);
#            check_mem();

#            for ( 1..TIMES_THROUGH ) {
#                my $str = encodeToUTF8( "iso-8859-2" , "abc" );
#            }
#            ok(1);
#            check_mem();
#
#            for ( 1..TIMES_THROUGH ) {
#                my $str = decodeFromUTF8( "iso-8859-1" , $encstr );
#            }
#            ok(1);
#            check_mem();
#        }
        {
            note("NAMESPACE TESTS");

            my $string = '<foo:bar xmlns:foo="bar"><foo:a/><foo:b/></foo:bar>';

            my $doc = LibXML.new().parse: :string( $string );

            for (1..TIMES_THROUGH) {
                my @ns = $doc.documentElement().getNamespaces();
                # warn "ns : " . $_.localname . "=>" . $_.href foreach @ns;
                my $prefix = .localname for @ns;
                my $name = $doc.documentElement.nodeName;
            }
            check_mem();
            pass('namespace tests.');
        }

        {
            note('SAX PARSER');

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
                for (1..TIMES_THROUGH) {
                    my $doc = $parser.parse: :string( %xmlStrings{$key} );
                }

                check_mem();
            }
            ok (1, 'SAX PARSER');
        }

        {
            note('PUSH PARSER');

        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>","<xml2><xml3></xml3></xml2>","</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ","<xml2>some text some text some text"," </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1","> <xml2> <!","-- some text -. <!-- some text -. <!--some text-",". </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ","<xml2><!","[CDATA[some text some text some text]","]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ','attr0="value0"> <xml2 attr1="value1"></xml2>',' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x','m="foo"><xm:xml2','/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">','<xm:xml2 xm:foo="bar"/></xm',':xml1>'],
        );

            my $handler = sax_null.new;
            my $parser  = LibXML.new;

            check_mem();
       if (0) {
            for %xmlStrings.keys.sort -> $key  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    (@%xmlStrings{$key}).map: { $parser.push( $_ ) } ;
                    my $doc = $parser.finish-push();
                }

                check_mem();
            }
            # Cancelled TEST
            pass(' TODO : Add test name');
        }
            my %xmlBadStrings = (
                "SIMPLE"      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>","</xml2>", "</xml1>"],
                "SIMPLE TEXT" => ["<xml1> ","some text some text some text","</xml2>"],
                "SIMPLE CDATA"=> ["<xml1> ","<!","[CDATA[some text some text some text]","</xml1>"],
                "SIMPLE JUNK" => ["<xml1/> ","junk"],
            );

            note('BAD PUSHED DATA');
            for ( "SIMPLE","SIMPLE2", "SIMPLE TEXT","SIMPLE CDATA","SIMPLE JUNK" ) -> $key  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    try {@(%xmlBadStrings{$key}).map: { $parser.push( $_ ) };};
                    try {my $doc = $parser.finish-push();};
                }

                check_mem();
            }
            pass('BAD PUSHED DATA');
        }

        {
            note('SAX PUSH PARSER');

            my $sax-handler = sax_null.new;
            my $parser  = LibXML.new: :$sax-handler;
            check_mem();


        my %xmlStrings = (
            "SIMPLE"      => ["<xml1>","<xml2><xml3></xml3></xml2>","</xml1>"],
            "SIMPLE TEXT" => ["<xml1> ","<xml2>some text some text some text"," </xml2> </xml1>"],
            "SIMPLE COMMENT" => ["<xml1","> <xml2> <!","-- some text -. <!-- some text -. <!--some text-",". </xml2> </xml1>"],
            "SIMPLE CDATA" => ["<xml1> ","<xml2><!","[CDATA[some text some text some text]","]></xml2> </xml1>"],
            "SIMPLE ATTRIBUTE" => ['<xml1 ','attr0="value0"> <xml2 attr1="value1"></xml2>',' </xml1>'],
            "NAMESPACES SIMPLE" => ['<xm:xml1 xmlns:x','m="foo"><xm:xml2','/></xm:xml1>'],
            "NAMESPACES ATTRIBUTE" => ['<xm:xml1 xmlns:xm="foo">','<xm:xml2 xm:foo="bar"/></xm',':xml1>'],
        );

            for %xmlStrings.keys.sort -> $key {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    try { @(%xmlStrings{$key}).map: { $parser.push( $_ ) };};
                    try {my $doc = $parser.finish-push();};
                }

                check_mem();
            }
            pass('SAX PUSH PARSER');

            note('BAD PUSHED DATA');

            my %xmlBadStrings = (
                "SIMPLE "      => ["<xml1>"],
                "SIMPLE2"      => ["<xml1>","</xml2>", "</xml1>"],
                "SIMPLE TEXT"  => ["<xml1> ","some text some text some text","</xml2>"],
                "SIMPLE CDATA" => ["<xml1> ","<!","[CDATA[some text some text some text]","</xml1>"],
                "SIMPLE JUNK"  => ["<xml1/> ","junk"],
            );

            for %xmlBadStrings.keys.sort -> $key  {
                print "# $key \n";
                for (1..TIMES_THROUGH) {
                    try { @(%xmlBadStrings{$key}).map: { $parser.push( $_ ) };};
                    try {my $doc = $parser.finish-push();};
                }

                check_mem();
            }
            pass('BAD PUSHED DATA');
        }
}

        summarise_mem();

sub processMessage($msg, $xpath) {
      my $parser = LibXML.new();

      my $doc  = $parser.parse: :string($msg);
      my $elm  = $doc.getDocumentElement;
      my $node = $doc.first($xpath);
      my $text = $node.to-literal;
#      undef $doc;   # comment this line to make memory leak much worse
#      undef $parser;
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
            if (/^VmRSS:.*?(\d+)/) {
                %mem<Resident> = $0;
            }
        }
        $FH.close;
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
    my $total-objects = LibXML::Raw::ref-total();
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

    #method startDocument(|) is sax-cb {
    #}

    #method xmlDecl(|) is sax-cb {
    #}

    #method startElement(|) is sax-cb {
    #}

    #method endElement(|) is sax-cb {
    #}

    #method startCData(|) is sax-cb {
    #}

    #method endCData(|) is sax-cb {
    #}

    #method startElementNS(|) is sax-cb {
    #}

    #method endElementNS(|) is sax-cb {
    #}

    #method characters(|) is sax-cb {
    #}

    #method comment(|) is sax-cb {
    #}


    #method endDocument(|) is sax-cb {
    #}

    #method error($ctx, $msg) is sax-cb {
    #    die( $msg );
    #}

 }
