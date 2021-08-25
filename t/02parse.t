use v6;
use Test;
##
# this test checks the parsing capabilities of LibXML
# it relies on the success of t/01basic.t

plan 578;
use LibXML;
use LibXML::Raw;
use LibXML::Namespace;
use LibXML::Node;
use LibXML::Enums;
use LibXML::SAX::Handler;
use LibXML::SAX::Handler::SAX2;
use LibXML::SAX::Handler::XML;
my \config = LibXML.config;

constant XML_DECL = "<?xml version=\"1.0\"?>\n";

# test values
my @goodWFStrings = (
    '<foobar/>',
    '<foobar></foobar>',
    XML_DECL ~ "<foobar></foobar>",
    '<?xml version="1.0" encoding="UTF-8"?>' ~ "\n<foobar></foobar>",
    '<?xml version="1.0" encoding="ISO-8859-1"?>' ~ "\n<foobar></foobar>",
    XML_DECL ~ "<foobar> </foobar>\n",
    XML_DECL ~ '<foobar><foo/></foobar> ',
    XML_DECL ~ '<foobar> <foo/> </foobar> ',
    XML_DECL ~ '<foobar><![CDATA[<>&"\']]></foobar>',
    XML_DECL ~ '<foobar>&lt;&gt;&amp;&quot;&apos;</foobar>',
    XML_DECL ~ '<foobar>&#x20;&#160;</foobar>',
    XML_DECL ~ '<!--comment--><foobar>foo</foobar>',
    XML_DECL ~ '<foobar>foo</foobar><!--comment-->',
    XML_DECL ~ '<foobar>foo<!----></foobar>',
    XML_DECL ~ '<foobar foo="bar"/>',
    XML_DECL ~ '<foobar foo="\'bar>"/>',
    #XML_DECL ~ '<bar:foobar foo="bar"><bar:foo/></bar:foobar>',
    #'<bar:foobar/>'
);

my @goodWFNSStrings = (
    XML_DECL ~ '<foobar xmlns:bar="xml://foo" bar:foo="bar"/>'~"\n",
    XML_DECL ~ '<foobar xmlns="xml://foo" foo="bar"><foo/></foobar>'~"\n",
    XML_DECL ~ '<bar:foobar xmlns:bar="xml://foo" foo="bar"><foo/></bar:foobar>'~"\n",
    XML_DECL ~ '<bar:foobar xmlns:bar="xml://foo" foo="bar"><bar:foo/></bar:foobar>'~"\n",
    XML_DECL ~ '<bar:foobar xmlns:bar="xml://foo" bar:foo="bar"><bar:foo/></bar:foobar>'~"\n",
);

my @goodWFDTDStrings = (
    XML_DECL ~ '<!DOCTYPE foobar ['~"\n"~'<!ENTITY foo " test ">'~"\n"~']>'~"\n"~'<foobar>&foo;</foobar>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;</foobar>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;&gt;</foobar>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar=&quot;foo&quot;">]><foobar>&foo;&gt;</foobar>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar>&foo;&gt;</foobar>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar foo="&foo;"/>',
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar foo="&gt;&foo;"/>',
);

my @badWFStrings = (
    "",                                        # totally empty document
    XML_DECL,                                  # only XML Declaration
    "<!--ouch-->",                             # comment only is like an empty document
    '<!DOCTYPE ouch [<!ENTITY foo "bar">]>',   # no good either ...
    '<ouch>',                                  # single tag (tag mismatch)
    '<ouch/>foo',                              # trailing junk
    'foo<ouch/>',                              # leading junk
    '<ouch foo=bar/>',                         # bad attribute
    '<ouch foo="bar/>',                        # bad attribute
    '<ouch>&</ouch>"=',                        # bad char
    '<ouch>&#0x20;</ouch>',                    # bad char
    '<ouch>&foo;</ouch>',                      # undefind entity
    '<ouch>&gt</ouch>',                        # unterminated entity
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar">]><foobar &foo;="ouch"/>',          # bad placed entity
    XML_DECL ~ '<!DOCTYPE foobar [<!ENTITY foo "bar=&quot;foo&quot;">]><foobar &foo;/>', # even worse
    '<ouch><!---></ouch>',                     # bad comment
    # see issue #18
    (LibXML.version >= v2.09.10 ?? '<ouch><!-----></ouch>' !! '<ouch><!---></ouch>'),
);


my %goodPushWF = (
    single1 => ['<foobar/>'],
    single2 => ['<foobar>','</foobar>'],
    single3 => [ XML_DECL, "<foobar>", "</foobar>" ],
    single4 => ["<foo", "bar/>"],
    single5 => ["<", "foo","bar", "/>"],
    single6 => ['<?xml version="1.0" encoding="UTF-8"?>',"\n<foobar/>"],
    single7 => ['<?xml',' version="1.0" ','encoding="UTF-8"?>',"\n<foobar/>"],
    single8 => ['<foobar', ' foo=', '"bar"', '/>'],
    single9 => ['<?xml',' versio','n="1.0" ','encodi','ng="U','TF8"?>',"\n<foobar/>"],
    multiple1 => [ '<foobar>','<foo/>','</foobar> ', ],
    multiple2 => [ '<foobar','><fo','o','/><','/foobar> ', ],
    multiple3 => [ '<foobar>','<![CDATA[<>&"\']]>','</foobar>'],
    multiple4 => [ '<foobar>','<![CDATA[', '<>&', ']]>', '</foobar>' ],
    multiple5 => [ '<foobar>','<!','[CDA','TA[', '<>&', ']]>', '</foobar>' ],
    multiple6 => ['<foobar>','&lt;&gt;&amp;&quot;&apos;','</foobar>'],
    multiple6 => ['<foobar>','&lt',';&','gt;&a','mp;','&quot;&ap','os;','</foobar>'],
    multiple7 => [ '<foobar>', '&#x20;&#160;','</foobar>' ],
    multiple8 => [ '<foobar>', '&#x','20;&#1','60;','</foobar>' ],
    multiple9 => [ '<foobar>','moo','moo','</foobar> ', ],
    multiple10 => [ '<foobar>','moo','</foobar> ', ],
    comment1  => [ '<!--comment-->','<foobar/>' ],
    comment2  => [ '<foobar/>','<!--comment-->' ],
    comment3  => [ '<!--','comment','-->','<foobar/>' ],
    comment4  => [ '<!--','-->','<foobar/>' ],
    comment5  => [ '<foobar>fo','o<!---','-><','/foobar>' ],
    attr1     => [ '<foobar',' foo="bar"/>'],
    attr2     => [ '<foobar',' foo','="','bar','"/>'],
    attr3     => [ '<foobar',' fo','o="b','ar"/>'],
    #prefix1   => [ '<bar:foobar/>' ],
    #prefix2   => [ '<bar',':','foobar/>' ],
    #prefix3   => [ '<ba','r:fo','obar/>' ],
    ns1       => [ '<foobar xmlns:bar="xml://foo"/>' ],
    ns2       => [ '<foobar ','xmlns:bar="xml://foo"','/>' ],
    ns3       => [ '<foo','bar x','mlns:b','ar="foo"/>' ],
    ns4       => [ '<bar:foobar xmlns:bar="xml://foo"/>' ],
    ns5       => [ '<bar:foo','bar xm','lns:bar="fo','o"/>' ],
    ns6       => [ '<bar:fooba','r xm','lns:ba','r="foo"','><bar',':foo/','></bar'~':foobar>'],
    dtd1      => [XML_DECL, '<!DOCTYPE ','foobar [','<!ENT','ITY foo " test ">',']>','<foobar>&f','oo;</foobar>',],
    dtd2      => [XML_DECL, '<!DOCTYPE ','foobar [','<!ENT','ITY foo " test ">',']>','<foobar>&f','oo;&gt;</foobar>',],
);

my $goodfile = "samples/dromeds.xml";
my $badfile1 = "samples/bad.xml";
my $badfile2 = "does_not_exist.xml";

my LibXML $parser .= new();

# 1 NON VALIDATING PARSER
# 1.1 WELL FORMED STRING PARSING
# 1.1.1 DEFAULT VALUES

{
    for flat @goodWFStrings, @goodWFNSStrings, @goodWFDTDStrings -> Str $string {
        my $doc = $parser.parse(:$string);
        isa-ok($doc, 'LibXML::Document');
    }
}

sub shorten_string($string is copy) { # Used for test naming.
  return "'undef'" unless $string.defined;

  $string ~~ s:g/\n/\\n/;
  return $string if $string.chars < 25;
  return $string.substr(0, 10) ~ "..." ~ $string.substr(*-10);
}

dies-ok { $parser.parse(:string(Str)) }, "parse undef string";

for @badWFStrings -> $string {
    throws-like { $parser.parse(:$string); },
        X::LibXML::Parser,
        "Error thrown passing '{shorten_string($string)}'";
}

# 1.1.2 NO KEEP BLANKS
{ 
    temp $parser.keep-blanks = False;

    for flat @goodWFStrings, @goodWFNSStrings, @goodWFDTDStrings -> $string {
	my $doc = $parser.parse(:$string);
        isa-ok($doc, 'LibXML::Document');
    }

    for @badWFStrings -> $string {
        dies-ok({ $parser.parse: :$string; }, "keep-blanks error:'{shorten_string($string)}'");
    }
}

# 1.1.3 EXPAND ENTITIES
{
    temp $parser.expand-entities = False;

    for flat @goodWFStrings, @goodWFNSStrings, @goodWFDTDStrings -> $string {
        my $doc = $parser.parse: :$string;
        isa-ok($doc, 'LibXML::Document');
    }

    dies-ok { $parser.parse: :string(Str); };

    for @badWFStrings -> $string {
        dies-ok { $parser.parse: :$string; }, "expand-entities error:'{shorten_string($string)}'";
    }

}

# 1.1.4 PEDANTIC
{
    temp $parser.pedantic-parser = True;

    for flat @goodWFStrings, @goodWFNSStrings, @goodWFDTDStrings -> $string {
        my $doc = $parser.parse(:$string);
	isa-ok($doc, 'LibXML::Document');
    }

    for @badWFStrings -> $string {
        dies-ok { $parser.parse(:$string); }, "pedantic-parser error:'{shorten_string($string)}'";
    }
}

# 1.2 PARSE A FILE

{
    my $doc = $parser.parse(:file($goodfile));
    isa-ok($doc, 'LibXML::Document');
}

throws-like( { $parser.parse(:file($badfile1))},
             X::LibXML::Parser,
             "Error thrown with bad xml file");


{
    my $string = "<a>    <b/> </a>";
    my $tstr = "<a><b/></a>\n";
    temp $parser.keep-blanks = False;
    temp config.skip-xml-declaration = True;
    my $docA = $parser.parse: :$string;
    my $docB = $parser.parse: :file("samples/test3.xml");
    is( $docA, $tstr, "xml string round trips as expected");
    is( $docB, $tstr, "test3.xml round trips as expected");
}

# 1.3 PARSE A HANDLE

my $io = $goodfile.IO;
isa-ok($io, IO::Path);
my $doc = $parser.parse: :$io;
isa-ok($doc, 'LibXML::Document');

$io .= open(:r, :bin);
isa-ok($io, IO::Handle);
$doc = $parser.parse: :$io;
isa-ok($doc, 'LibXML::Document');

$io = $badfile1.IO;
isa-ok($io, IO::Path);
throws-like
    { $parser.parse: :$io; },
    X::LibXML::Parser, :message(rx/:s Extra content at the end of the document/), "error parsing bad file from file handle of $badfile1";
{
    temp $parser.expand-entities = True;
    my $doc = $parser.parse: :file( "samples/dtd.xml" );

    my $root = $doc.documentElement;
    isa-ok($root, 'LibXML::Element');
    my LibXML::Node @cn = $root.childNodes;
    is( +@cn, 1, "1 child node" );

    $parser.expand-entities = False;
    $doc = $parser.parse: :file( "samples/dtd.xml" );
    @cn = $doc.documentElement.childNodes;
    is( +@cn, 3, "3 child nodes" );

    temp $parser.dtd = True;
    $doc = $parser.parse: :file( "samples/complex/complex2.xml" );
    @cn = $doc.documentElement.childNodes;
    is( +@cn, 1, "1 child node" );
}


# 1.4 x-include processing

my $goodXInclude = q{
<x>
<xinclude:include
 xmlns:xinclude="http://www.w3.org/2001/XInclude"
 href="test2.xml"/>
</x>
};


my $badXInclude = q{
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xinclude:include href="bad.xml"/>
</x>
};


{
    $parser.URI = "samples/";
    temp $parser.keep-blanks = False;
    my $doc = $parser.parse: :string( $goodXInclude );
    isa-ok($doc, 'LibXML::Document');

    my $i;
    lives-ok { $i = $parser.processXIncludes($doc); };
    is( $i, "1", "return value from processXIncludes == 1");

    $doc = $parser.parse: :string( $badXInclude );
    $i = Nil;

    throws-like { $parser.processXIncludes($doc); },
        X::LibXML::Parser,
        :message(rx/'Extra content at the end of the document'/),
        "error parsing a bad include";

    # auto expand
    temp $parser.expand-xinclude = True;
    $doc = $parser.parse: :string( $goodXInclude );
    isa-ok($doc, 'LibXML::Document');

    $doc = Nil;
    throws-like { $doc = $parser.parse: :string( $badXInclude ); },
        X::LibXML::Parser,
        :message(rx/'samples/bad.xml:3: parser error : Extra content at the end of the document'/),
         "error parsing $badfile1 in include";
    ok(!$doc.defined, "no doc returned");

    # some bad stuff
    throws-like { $parser.processXIncludes(Str); },
    X::TypeCheck::Binding::Parameter, "Error parsing undef include";

    throws-like { $parser.processXIncludes("blahblah"); },
    X::TypeCheck::Binding::Parameter, "Error parsing bogus include";
}


# 2 PUSH PARSER

{
    my LibXML $pparser .= new();
    # 2.1 PARSING WELLFORMED DOCUMENTS
    for qw<single1 single2 single3 single4 single5 single6
                         single7 single8 single9 multiple1 multiple2 multiple3
                         multiple4 multiple5 multiple6 multiple7 multiple8
                         multiple9 multiple10 comment1 comment2 comment3
                         comment4 comment5 attr1 attr2 attr3
			 ns1 ns2 ns3 ns4 ns5 ns6 dtd1 dtd2> -> $key {
        for %goodPushWF{$key}.list {
            $pparser.parse-chunk( $_ );
        }

        my $doc;
        lives-ok {$doc = $pparser.parse-chunk("", :terminate); }, "No error parsing $key";
	isa-ok($doc, 'LibXML::Document', "Document came back parsing chunk: ");
    }
}

{

    my @good_strings = ("<foo>", "bar", "</foo>" );
    my %bad_strings  = (
                            predocend1   => ["<A>" ],
                            predocend2   => ["<A>", "B"],
                            predocend3   => ["<A>", "<C>"],
                            predocend4   => ["<A>", "<C/>"],
                            postdocend1  => ["<A/>", "<C/>"],
                            postdocend2  => ["<A/>", "B"],
                            postdocend3  => ["<A/>", "BB"],
                            badcdata     => ["<A> ","<!","[CDATA[B]","</A>"],
                            badending1   => ["<A> ","B","</C>"],
                            badending2   => ["<A> ","</C>","</A>"],
                       );

    my LibXML $parser .= new;
    {
        for @good_strings {
            $parser.parse-chunk( $_ );
        }
        my $doc = $parser.parse-chunk("",:terminate);
        isa-ok($doc, 'LibXML::Document', "parse multipe chunks");
    }

    {
        # 2.2 PARSING BROKEN DOCUMENTS
        my $doc;
        for %bad_strings.keys.sort -> $key {
            $doc = Nil;
	    my $bad-chunk;
            my $err;
            for @(%bad_strings{$key}) -> $chunk {
                try {
                    $parser.parse-chunk( $chunk );
                    CATCH { default { $err = .message; $bad-chunk = $chunk; } };
                }
                last if $bad-chunk;
            }

            dies-ok { $doc = $parser.parse-chunk('', :terminate)}, "Got an error parsing empty chunk after chunks for $key";
        }

    }

    {
        # 2.3 RECOVERING PUSH PARSER
        $parser.init-push;

        for "<A>", "B" {
            $parser.push($_);
        }

        my $doc;
        quietly {
            $doc = $parser.finish-push(:recover);
        };
        isa-ok( $doc, 'LibXML::Document', 'RECOVERING PUSH PARSER' );
    }
}

use LibXML::SAX;
# 3 SAX PARSER
{
    my LibXML::SAX::Handler::XML $sax-handler .= new;
    my LibXML::SAX $generator .= new: :$sax-handler;

    my $string  = q{<bar foo="bar">foo</bar>};

    $doc = $generator.parse: :$string;
    isa-ok( $doc , 'XML::Document', 'SAX PARSER');

}

{
    my LibXML::SAX::Handler::SAX2 $sax-handler .= new;
    my LibXML::SAX $generator .= new: :$sax-handler;

    my $string  = q{<bar foo="bar">foo</bar>};

    $doc = $generator.parse: :$string;
    isa-ok( $doc , 'LibXML::Document');

    # 3.1 GENERAL TESTS
    for @goodWFStrings -> $string {
        my $doc = $generator.parse: :$string;
        isa-ok( $doc , 'LibXML::Document', 'SAX Handler on good strings');
    }

    # CDATA Sections

    $string = q{<foo><![CDATA[&foo<bar]]></foo>};

    $doc = $generator.parse: :$string;
    my @cn = $doc.documentElement.childNodes();
    is( + @cn, 1, "Child nodes - 1" );
    is( @cn[0].nodeType, +XML_CDATA_SECTION_NODE );
    is( @cn[0].content, '&foo<bar' );
    is( @cn[0].Str, '<![CDATA[&foo<bar]]>');

    # 3.2 NAMESPACE TESTS

    my $i = 0;
    for @goodWFNSStrings -> $string {
        my $doc = $generator.parse: :$string;
        isa-ok( $doc , 'LibXML::Document');

        is( $doc.Str.subst(/' encoding="UTF-8"'/, ''), $string, "Good NS $i" );
        $i++
    }

    $doc = $generator.parse: :string(q{<foo bar="x" baz="y" />});
    my LibXML::Node:D $root = $doc.documentElement;
    # attributes as a tied hash
    my $attrs := $root.attributes;
    is(+$attrs , 2, "2 attributes");
    # attributes via an iterator
    my LibXML::Attr @props = $root.properties;
    is(+@props , 2, "2 properties");
    my $props = $root.properties;
    is $props[0], @props[0];
    is $props[1], @props[1];
    is $props.head, @props[0];
    is $props.tail, @props[1];
    is $attrs<bar>, @props[0];
    is $attrs<baz>, @props[1];

    # DATA CONSISTENCE
    # find out if namespaces are there

    my $string2 = q{<foo xmlns:bar="http://foo.bar">bar<bar:bi/></foo>};

    $doc = $generator.parse: :string($string2);

    my LibXML::Namespace @namespaces = $doc.documentElement.namespaces;

    is(+ @namespaces , 1, "1 namespace");
    is( @namespaces[0].type, +XML_NAMESPACE_DECL, "Node type: " ~ +XML_NAMESPACE_DECL );

    $root = $doc.documentElement;

    my $vstring = q{<foo xmlns:bar="http://foo.bar">bar<bar:bi/></foo>};
    is($root.Str, $vstring );


    # 3.3 INTERNAL SUBSETS

    for @goodWFDTDStrings -> $string {
        my $doc = $generator.parse: :$string;
        isa-ok $doc , 'LibXML::Document', "dtd $string";
    }

    # 3.5 PARSE FILE
    $doc = $generator.parse: :file("samples/test.xml");
    isa-ok $doc, 'LibXML::Document';


}

# 4 SAXY PUSHER

{
    my LibXML::SAX::Handler::SAX2 $sax-handler .= new;
    my LibXML::SAX $parser .= new: :$sax-handler;

    $parser.push( '<foo/>' );
    my $doc = $parser.finish-push;
    isa-ok($doc , 'LibXML::Document');

    for %goodPushWF.keys.sort -> $key {
        for @(%goodPushWF{$key}) {
            $parser.push( $_);
        }

        my $doc;
        lives-ok {$doc = $parser.finish-push; }, "sax push parse $key";
        isa-ok( $doc , 'LibXML::Document', "sax push parse $key");
    }
}

# 5 PARSE WELL BALANCED CHUNKS
{
    my $MAX_WF_C = 11;
    my $MAX_WB_C = 16;

    my %chunks = (
                    wellformed1  => '<A/>',
                    wellformed2  => '<A></A>',
                    wellformed3  => '<A B="C"/>',
                    wellformed4  => '<A>D</A>',
                    wellformed5  => '<A><![CDATA[D]]></A>',
                    wellformed6  => '<A><!--D--></A>',
                    wellformed7  => '<A><K/></A>',
                    wellformed8  => '<A xmlns="xml://E"/>',
                    wellformed9  => '<F:A xmlns:F="xml://G" F:A="B">D</F:A>',
                    wellformed10 => '<!--D-->',
                    wellformed11  => '<A xmlns:F="xml://E"/>',
                    wellbalance1 => '<A/><A/>',
                    wellbalance2 => '<A></A><A></A>',
                    wellbalance3 => '<A B="C"/><A B="H"/>',
                    wellbalance4 => '<A>D</A><A>I</A>',
                    wellbalance5 => '<A><K/></A><A><L/></A>',
                    wellbalance6 => '<A><![CDATA[D]]></A><A><![CDATA[I]]></A>',
                    wellbalance7 => '<A><!--D--></A><A><!--I--></A>',
                    wellbalance8 => '<F:A xmlns:F="xml://G" F:A="B">D</F:A><J:A xmlns:J="xml://G" J:A="M">D</J:A>',
                    wellbalance9 => 'D<A/>',
                    wellbalance10=> 'D<A/>D',
                    wellbalance11=> 'D<A/><!--D-->',
                    wellbalance12=> 'D<A/><![CDATA[D]]>',
                    wellbalance13=> '<![CDATA[D]]><A/>D',
                    wellbalance14=> '<!--D--><A/>',
                    wellbalance15=> '<![CDATA[D]]>',
                    wellbalance16=> 'D',
                 );

    my @badWBStrings = (
        "",
        "<ouch>",
        "<ouch>bar",
        "bar</ouch>",
        "<ouch/>&foo;", # undefined entity
        "&",            # bad char
       ## "h\x[e4]h?",         # bad encoding
        "<!--->",       # bad stays bad ;)
        "<!----->",     # bad stays bad ;)
    );


    my LibXML $pparser .= new;

    # 5.1 DOM CHUNK PARSER

    for 1 .. $MAX_WF_C -> $_ is copy {
        my Str:D $string = %chunks{'wellformed' ~ $_};
        my $frag = $pparser.parse-balanced: :$string;
        isa-ok $frag, 'LibXML::DocumentFragment';
        if $frag.nodeType == +XML_DOCUMENT_FRAG_NODE
             && $frag.hasChildNodes {
            if $frag.firstChild.isSameNode($frag.lastChild) {
                if $string ~~ /'<A></A>'/ {
                    $_--; # because we cannot distinguish between <a/> and <a></a>
                }

                is($frag.Str, %chunks{'wellformed' ~ $_}, $string ~ " is well formed");
                next;
            }
        }
        fail("Unexpected fragment without child nodes");
    }

    for 1 .. $MAX_WB_C -> $_ is copy {
        my Str:D $string = %chunks{'wellbalance' ~ $_};
        my $frag = $pparser.parse-balanced: :$string;
        isa-ok($frag, 'LibXML::DocumentFragment');
        if $frag.nodeType == +XML_DOCUMENT_FRAG_NODE
             && $frag.hasChildNodes {
            if $string ~~ /'<A></A>'/ {
                $_--;
            }
            is($frag.Str, %chunks{'wellbalance' ~ $_}, $string ~ " is well balanced");
            next;
        }
        flunk("Can't test balancedness");
    }

    dies-ok { $pparser.parse-balanced: :string(Mu); };

    dies-ok { $pparser.parse-balanced: :string(""); };

    for @badWBStrings -> $string {
        dies-ok({ $pparser.parse-balanced: :$string; }, "parse-balanced fails: $string");
    }

    {
        # 5.1.1 Segmentation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my LibXML $parser .= new();
        my $doc = $parser.parse-balanced: :string( $sDoc);
        my $chk = $parser.parse-balanced: :string( $sChunk);

        my $fc = $doc.firstChild;
        isa-ok($fc, 'LibXML::Element');

        $doc.appendChild( $chk );

        is( $doc.Str, '<C/><D/><A/><B/>', 'appendChild');
    }

    {
        # 5.1.2 Segmentation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my LibXML $parser .= new();
        my $doc = $parser.parse-balanced: :string($sDoc);
        my $chk = $parser.parse-balanced: :string($sChunk);

        my $fc = $doc.firstChild;
        isa-ok($fc, 'LibXML::Element');

        $doc.insertAfter( $chk, $fc );

        is( $doc.Str, '<C/><A/><B/><D/>', 'insertAfter');
    }

    {
        # 5.1.3 Segmentation fault tests

        my $sDoc   = '<C/><D/>';
        my $sChunk = '<A/><B/>';

        my LibXML $parser .= new();
        my $doc = $parser.parse-balanced: :string($sDoc);
        my $chk = $parser.parse-balanced: :string($sChunk);

        my $fc = $doc.firstChild;

        $doc.insertBefore( $chk, $fc );

        is( $doc.Str, '<A/><B/><C/><D/>', 'insertBefore' );
    }

    pass("Made it to SAX test without seg fault");

    # 5.2 SAX CHUNK PARSER

    my LibXML::SAX::Handler::SAX2 $sax-handler .= new;
    my LibXML::SAX $parser .= new: :$sax-handler;

    for 1 .. $MAX_WF_C -> $_ is copy {
        my $string = %chunks{'wellformed' ~ $_};
        my $frag = $parser.parse-balanced: :$string;
        isa-ok($frag, 'LibXML::DocumentFragment');
        if ( $frag.nodeType == +XML_DOCUMENT_FRAG_NODE
             && $frag.hasChildNodes ) {
            if $frag.firstChild.isSameNode( $frag.lastChild ) {
                if $string ~~ /'<A></A>'/ {
                    $_--;
                }
                is($frag.Str, %chunks{'wellformed' ~ $_}, $string ~ ' is well formed');
                next;
            }
        }
        flunk("Couldn't pass well formed test since frag was bad");
    }

    for 1 .. $MAX_WB_C -> $_ is copy {
        my Str:D $string = %chunks{'wellbalance' ~ $_};
        my $frag = $parser.parse-balanced: :$string;
        isa-ok($frag, 'LibXML::DocumentFragment');
        if ( $frag.nodeType == XML_DOCUMENT_FRAG_NODE
             && $frag.hasChildNodes ) {
            if $string ~~ /'<A></A>'/ {
                $_--;
            }
            is($frag.Str, %chunks{'wellbalance' ~ $_}, $string ~ " is well balanced");
            next;
        }
        flunk("Couldn't pass well balanced test since frag was bad");
    }
}

{
    # 6 VALIDATING PARSER

    my %badstrings = (
                    SIMPLE => '<?xml version="1.0"?>'~"\n<A/>\n",
                  );
    my LibXML $parser .= new;

    $parser.validation = True;
    my $doc;
    dies-ok({ $doc = $parser.parse: :string(%badstrings<SIMPLE>); }, "Failed to parse SIMPLE bad string");
}

{
    # 7 LINE NUMBERS

    my $goodxml = q:to<EOXML>;
    <?xml version="1.0"?>
    <foo>
        <bar/>
    </foo>
    EOXML

    my $badxml = q:to<EOXML>;
    <?xml version="1.0"?>
    <!DOCTYPE foo [<!ELEMENT foo EMPTY>]>
    <bar/>
    EOXML

    my LibXML $parser .= new;
    $parser.validation = True;

    throws-like { $parser.parse: :string( $badxml ); },
    X::LibXML::Parser,
    # correct line number may or may not be present
    # depending on libxml2 version
    :message(rx/^^\:<[03]>\:/), "line 03 found in error";

    $parser.line-numbers = True;
    throws-like { $parser.parse: :string( $badxml ); },
    X::LibXML::Parser, :message(rx/^^\:3\:/), "line 3 found in error";

    # switch off validation for the following tests
    $parser.validation = False;

    my $doc;
    lives-ok { $doc = $parser.parse: :string( $goodxml ); };

    my $root = $doc.documentElement();
    is( $root.line-number(), 2, "line number is 2");

    my LibXML::Node @kids = $root.childNodes();
    is( @kids[1].line-number(),3, "line number is 3" );

    my $newkid = $root.appendChild( $doc.createElement( "bar" ) );
    is( $newkid.line-number(), 0, "line number is 0");

    $parser.line-numbers = False;
    lives-ok { $doc = $parser.parse: :string( $goodxml ); };

    $root = $doc.documentElement();
    is( $root.line-number(), 0, "line number is 0");

    @kids = $root.childNodes();
    is( @kids[1].line-number(), 0, "line number is 0");
}

{
    my Str ( $xsDoc1, $xsDoc2 );
    my Str $fn1 = "samples/xmlns/goodguy.xml";
    my Str $fn2 = "samples/xmlns/badguy.xml";

    $xsDoc1 = q{<A:B xmlns:A="http://D"><A:C xmlns:A="http://D"></A:C></A:B>};
    $xsDoc2 = q{<A:B xmlns:A="http://D"><A:C xmlns:A="http://E"/></A:B>};

    my LibXML $parser .= new();
    $parser.clean-namespaces = True;

    is( $parser.parse(:string( $xsDoc1 )).documentElement.Str,
        q{<A:B xmlns:A="http://D"><A:C/></A:B>}, "string ns parse" );
    is( $parser.parse(:string( $xsDoc2 )).documentElement.Str,
        $xsDoc2, "string ns parse" );

    is( $parser.parse(:file($fn1)).documentElement.Str,
        q{<A:B xmlns:A="http://D"><A:C/></A:B>}, "file ns parse" );
    is( $parser.parse(:file($fn2)).documentElement.Str,
        $xsDoc2, "file ns parse" );

    my $fh1 = $fn1.IO;
    my $fh2 = $fn2.IO;

    is( $parser.parse(:io($fh1)).documentElement,
        q{<A:B xmlns:A="http://D"><A:C/></A:B>}, "io ns parse" );
    is( $parser.parse(:io($fh2 )).documentElement ,
        $xsDoc2, "io ns parse" );

    my @xaDoc1 = ('<A:B xmlns:A="http://D">','<A:C xmlns:A="h','ttp://D"/>' ,'</A:B>');
    my @xaDoc2 = ('<A:B xmlns:A="http://D">','<A:C xmlns:A="h','ttp://E"/>' , '</A:B>');

    my $doc;

    for @xaDoc1 {
        $parser.parse-chunk($_);
    }
    $doc = $parser.parse-chunk: :terminate;

    is( $doc.documentElement,
        q{<A:B xmlns:A="http://D"><A:C/></A:B>}, "chunk ns parse" );


    for @xaDoc2 {
        $parser.parse-chunk( $_ );
    }
    $doc = $parser.parse-chunk: :terminate;
    is( $doc.documentElement,
        $xsDoc2, "chunk ns parse" );
};

##
# test if external subsets are loaded correctly

{
    my $xmldoc = q:to<EOXML>;
    <!DOCTYPE X SYSTEM "samples/ext_ent.dtd">
    <X>&foo;</X>
    EOXML
    my LibXML $parser .= new;

    $parser.load-ext-dtd = True;

    # first time it should work
    my $doc    = $parser.parse: :string( $xmldoc );
    is( $doc.documentElement.string-value(), " test " );

    # second time it must not fail.
    my $doc2   = $parser.parse: :string( $xmldoc );
    is( $doc2.documentElement().string-value(), " test " );
}

{
    my $xmldoc = q:to<EOXML>;
    <!DOCTYPE X SYSTEM "samples/ext_ent.dtd">
    <X>&foo;</X>
    EOXML
    my LibXML $parser .= new();

    $parser.load-ext-dtd = True;

    # first time it should work
    my $doc    = $parser.parse: :string( $xmldoc );
    is( $doc.documentElement.string-value(), " test " );

    # lets see if load_ext_dtd = False works
    $parser.load-ext-dtd = False;
    my $doc2;
    dies-ok {
       $doc2    = $parser.parse: :string( $xmldoc );
    };

    $parser.validation = False;
    $parser.load-ext-dtd = False;
    my $doc3;
    lives-ok {
       $doc3 = $parser.parse: :file( "samples/article_external_bad.xml" );
    };

    isa-ok( $doc3, 'LibXML::Document');

    $parser.validation = True;
    $parser.load-ext-dtd = True;
    dies-ok {
       $doc3 = $parser.parse: :file( "samples/article_external_bad.xml" );
    };

}

{

   my LibXML $parser .= new();

   my $doc = $parser.parse: :string('<foo xml:base="foo.xml"/>'), :URI<bar.xml>;
   my $el = $doc.documentElement;
   is( $doc.URI, "bar.xml", "xml uris" );
   is( $doc.baseURI, "bar.xml", "xml uris" );
   is( $el.baseURI, "foo.xml", "xml uris" );

   $doc.URI = "baz.xml";
   is( $doc.URI, "baz.xml", "xml uris" );
   is( $doc.baseURI, "baz.xml", "xml uris" );
   is( $el.baseURI, "foo.xml", "xml uris" );

   $doc.baseURI = "bag.xml";
   is( $doc.URI, "bag.xml", "xml uris" );
   is( $doc.baseURI, "bag.xml", "xml uris" );
   is( $el.baseURI, "foo.xml", "xml uris" );

   $el.baseURI = "bam.xml" ;
   is( $doc.URI, "bag.xml", "xml uris" );
   is( $doc.baseURI, "bag.xml", "xml uris" );
   is( $el.baseURI, "bam.xml", "xml uris" );

}

{

   my LibXML $parser .= new();

   my $doc = $parser.parse: :html, :string('<html><head><base href="foo.html"></head><body></body></html>'), :URI<bar.html>;
   my $el = $doc.documentElement;
   is( $doc.URI, "bar.html", "html uris" );
   is( $doc.baseURI, "foo.html", "html uris" );
   is( $el.baseURI, "foo.html", "html uris" );

   $doc.URI = "baz.html";
   is( $doc.URI, "baz.html", "html uris" );
   is( $doc.baseURI, "foo.html", "html uris" );
   is( $el.baseURI, "foo.html", "html uris" );

}

{
    my LibXML $parser .= new();
    my $file = 't/data/chinese.xml';
    lives-ok {
        $parser.parse: :$file;
    };
    lives-ok {
        $parser.parse: :io($file);
    };
   
}


