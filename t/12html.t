use v6;
use Test;
use LibXML;

plan 55;

use LibXML;
use LibXML::Native;
use LibXML::Document;

constant CanDoIO = ? IO::Handle.can('do-not-close-automatically');

pass(' TODO : Add test name');

my $html = "example/test.html";

my $parser = LibXML.new();
{
    my LibXML::Document::HTML $doc = $parser.parse: :html, :file($html);
    ok($doc, ' TODO : Add test name');
    isa-ok($doc.native, htmlDoc, 'HTML, under the hood');
    cmp-ok $doc, '~~', LibXML::Document::HTML, "is HTML";
    cmp-ok $doc, '!~~', LibXML::Document::XML, "isn't XML";
}


my $io = $html.IO.open(:r);

my Str:D $string = $io.slurp;
$io.seek(0, SeekFromBeginning );


ok($string, ' TODO : Add test name');

my $doc = $parser.parse: :html, :$string;


ok($doc, ' TODO : Add test name');

if CanDoIO {
    $doc = $parser.parse: :html, :$io;
}
else {
    note 'parse :$io tests need Rakudo > 2020.05';
}

ok($doc, ' TODO : Add test name');

# parsing HTML's CGI calling links

my $strhref = q:to<EOHTML>;

<html>
    <body>
        <a href="http:/foo.bar/foobar.pl?foo=bar&bar=foo">
            foo
        </a>
        <p>test
    </body>
</html>
EOHTML

my $htmldoc;

$parser.recover = True;
quietly {
    $htmldoc = $parser.parse: :html, :string( $strhref );
};

# ok( not $@ );
ok( $htmldoc, ' TODO : Add test name' );
my $body = $htmldoc<html/body>.first;
$body.addNewChild(Str, 'InPut');
is $body.lastChild.tagName, 'InPut';
is-deeply $body.keys.sort, ('InPut', 'a', 'p', 'text()');
is +$body<InPut>, 1, "case sensitivity on assoc get";

# parse_html_string with encoding
# encodings
{
    my $utf_str = "ěščř";
    # w/o 'meta' charset
    $strhref = qq:to<EOHTML>;
<html>
  <body>
    <p>{$utf_str}</p>
  </body>
</html>
EOHTML

    ok($strhref, ' TODO : Add test name' );
    $htmldoc = $parser.parse: :html, :string( $strhref );
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :string($strhref);
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    my $enc = 'iso-8859-2';
    my $iso_8859_str = buf8.new(0xEC, 0xB9, 0xE8, 0xF8).decode("latin-1");
    my Blob $buf = $strhref.subst($utf_str, $iso_8859_str).encode("latin-1");
    
    $htmldoc = $parser.parse: :html, :$buf, :$enc;
    ok( $htmldoc && $htmldoc.getDocumentElement.defined, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    # w/ 'meta' charset
    $strhref = qq:to<EOHTML>;
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html;
      charset=iso-8859-2">
  </head>
  <body>
    <p>{$utf_str}</p>
  </body>
</html>
EOHTML

    $htmldoc = $parser.parse: :html, :string( $strhref,);
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $buf = $strhref.subst($utf_str, $iso_8859_str).encode("latin-1");
    $htmldoc = $parser.parse: :html, :$buf, :$enc;
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :$buf, :$enc, :URI<foo>;
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    is($htmldoc.URI, 'foo', ' TODO : Add test name');
}

# parse example/enc_latin2.html
# w/ 'meta' charset
{

    my $utf_str = "ěščř";
    my $test_file = 'example/enc_latin2.html';
    my $fh;

    $htmldoc = $parser.parse: :html, :file( $test_file );
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );

    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :file($test_file), :enc<iso-8859-2>, :URI<foo>;
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    is($htmldoc.URI, 'foo', ' TODO : Add test name');

    if CanDoIO {
        my $io = $test_file.IO;
        $doc = $parser.parse: :html, :$io;
    }
    else {
        note 'parse :$io tests need Rakudo > 2020.05';
        $doc = $parser.parse: :html, :file($html);
    }

    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    if CanDoIO {
        my $io = $test_file.IO.open(:r);
        $htmldoc = $parser.parse: :html, :$io, :enc<iso-8859-2>, :URI<foo>;
    }
    else {
        note 'parse :$io tests need Rakudo > 2020.05';
        $htmldoc = $parser.parse: :html, :file($test_file), :enc<iso-8859-2>, :URI<foo>;
    }
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.URI, 'foo', ' TODO : Add test name');
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

# iso-8859-2 encoding is NYI Rakudo.
skip "iso-8859-2 nyi", 2;
=begin TODO
    {
        my $num_tests = 2;

        # translate to UTF8 on perl-side
        $io = $test_file.IO.open( :r,  :enc<iso-8859-2>);
        $htmldoc = $parser.parse, :html, :$io, :enc<utf-8>;
        ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
        is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    }
=end TODO
}

# parse example/enc2_latin2.html
# w/o 'meta' charset
{
    my $utf_str = "ěščř";
    my $test_file = 'example/enc2_latin2.html';
    my $fh;

    $htmldoc = $parser.parse: :html, :file($test_file), :enc<iso-8859-2>;
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $io = $test_file.IO;
    if CanDoIO {
        $htmldoc = $parser.parse: :html, :$io, :enc<iso-8859-2>;
    }
    else {
        note 'parse :$io tests need Rakudo > 2020.05';
        $htmldoc = $parser.parse: :html, :file($test_file), :enc<iso-8859-2>;
    }
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

}

{
    my $html = q:to<EOF>;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Test &amp; Test some more</title>
</head>
<body>
<p>Meet you at the caf&eacute;?</p>
<p>How about <a href="http://example.com?mode=cafe&id=1&ref=foo">this one</a>?
</p>
<input class="wibble" id="foo" value="working" />
</body>
</html>
EOF

    my $parser = LibXML.new;
    $doc = Nil;
    quietly lives-ok {
        $doc = $parser.parse: :html, :string($html), :recover, :suppress-errors;
    };
    ok ($doc.defined, ' Parsing was successful.');
    my $root = $doc && $doc.documentElement;
    my $val = $root && $root.findvalue('//input[@id="foo"]/@value');
    is($val, 'working', 'XPath');
}


{

    # HTML_PARSE_NODEFDTD

    default {
        my $html = q{<body bgcolor='#ffffff' style="overflow: hidden;" leftmargin=0 MARGINWIDTH=0 CLASS="text">};
        my $p = LibXML.new;
        
        like( $p.parse( :html, :string( $html),
                        :recover,
                        :!def-dtd,
                        :enc<UTF-8>).Str, /^'<html>'/, 'do not add a default DOCTYPE' );

        like( $p.parse(:html, :string( $html),
                        :recover,
                        :enc<UTF-8>).Str, /^'<!DOCTYPE html'/, 'add a default DOCTYPE' );
    }
}

{

 #  Case sensitivity

my $strhref = q:to<EOHTML>;

<html>
    <body>
        <a href="http:/foo.bar/foobar.pl">foo</a>
        <A href="http:/foo.bar/foobar.pl">bar</a>
        <A HREF="http:/foo.bar/foobar.pl">BAZ</A>
        <p>test
        <P>test
    </body>
</html>
EOHTML

my $htmldoc;

quietly {
    $htmldoc = $parser.parse: :html, :string( $strhref );
};

my @as = $htmldoc.find('/html/body/a');
my @hrefs = $htmldoc.find('/html/body/a/@href');

is +@as, 3;
is @as.map(*.xpath-key).join(','), 'a,a,a';
is @as.map(*.tag).join(','), 'a,a,a';
is @as.map(*.ast-key).join(','), 'a,a,a';

is +@hrefs, 3;
is @hrefs.map(*.xpath-key).join(','), '@href,@href,@href';
is @hrefs.map(*.tag).join(','), 'href,href,href';
is @hrefs.map(*.ast-key).join(','), 'href,href,href';

}
