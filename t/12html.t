use v6;
use Test;
use LibXML;

plan 42;

use LibXML;

# TEST
ok(1, ' TODO : Add test name');

my $html = "example/test.html";

my $parser = LibXML.new();
{
    my $doc = $parser.parse: :html, :file($html);
    # TEST
    ok($doc, ' TODO : Add test name');
}

my $io = $html.IO.open(:r);

my Str:D $string = $io.slurp;
$io.seek(0, SeekFromBeginning );

# TEST

ok($string, ' TODO : Add test name');

my $doc = $parser.parse: :html, :$string;

# TEST

ok($doc, ' TODO : Add test name');

$doc = $parser.parse: :html, :$io;

# TEST

ok($doc, ' TODO : Add test name');

$io.close();

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
# TEST
ok( $htmldoc, ' TODO : Add test name' );

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

    # TEST
    ok($strhref, ' TODO : Add test name' );
    $htmldoc = $parser.parse: :html, :string( $strhref );
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :string($strhref);
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    my $enc = 'iso-8859-2';
    my $iso_8859_str = buf8.new(0xEC, 0xB9, 0xE8, 0xF8).decode("latin-1");
    my Blob $buf = $strhref.subst($utf_str, $iso_8859_str).encode("latin-1");
    
    $htmldoc = $parser.parse: :html, :$buf, :$enc;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
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
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $buf = $strhref.subst($utf_str, $iso_8859_str).encode("latin-1");
    $htmldoc = $parser.parse: :html, :$buf, :$enc;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :$buf, :$enc, :URI<foo>;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    # TEST
    is($htmldoc.URI, 'foo', ' TODO : Add test name');
}

# parse example/enc_latin2.html
# w/ 'meta' charset
{

    my $utf_str = "ěščř";
    my $test_file = 'example/enc_latin2.html';
    my $fh;

    $htmldoc = $parser.parse: :html, :file( $test_file );
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );

    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $htmldoc = $parser.parse: :html, :file($test_file), :enc<iso-8859-2>, :URI<foo>;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    # TEST
    is($htmldoc.URI, 'foo', ' TODO : Add test name');

    my $io = $test_file.IO;
    $htmldoc = $parser.parse: :html, :$io;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $io = $test_file.IO.open(:r);
    $htmldoc = $parser.parse: :html, :$io, :enc<iso-8859-2>, :URI<foo>;
    $io.close;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.URI, 'foo', ' TODO : Add test name');
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

# iso-8859-2 encoding is NYI Rakudo.
skip "iso-8859-2 nyi", 2;
=begin TODO
    {
        my $num_tests = 2;

        if v2.06.27 > LibXML.parser-version {
            skip("skipping for libxml2 < 2.6.27", $num_tests);
        }
        # translate to UTF8 on perl-side
        $io = $test_file.IO.open( :r,  :enc<iso-8859-2>);
        $htmldoc = $parser.parse, :html, :$io, :enc<utf-8>;
        $io.close;
        # TEST
        ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
        # TEST
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
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

    $io = $test_file.IO;
    $htmldoc = $parser.parse: :html, :$io, :enc<iso-8859-2>;
    # TEST
    ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
    # TEST
    is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');

}; skip "port remaining tests", 6;
=begin TODO

    SKIP:
    {
        my $num_tests = 2;

        # LibXML_read_perl doesn't play well with encoding layers. Skip
        # unconditionally for now.
        skip("skipping until LibXML_read_perl is fixed", $num_tests);

        if (1000*$] < 5008)
        {
            skip("skipping for Perl < 5.8", $num_tests);
        }
        # translate to UTF8 on perl-side
        open my $fh, '<:encoding(iso-8859-2)', $test_file
            or die "Cannot open '$test_file' for reading - $!";
        $htmldoc = $parser.parse_html_fh( $fh, { encoding => 'UTF-8' } );
        close $fh;
        # TEST
        ok( $htmldoc && $htmldoc.getDocumentElement, ' TODO : Add test name' );
        # TEST
        is($htmldoc.findvalue('//p/text()'), $utf_str, ' TODO : Add test name');
    }
}


{
  # 44715

  my $html = <<'EOF';
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
  eval {
    $doc = $parser.parse: :html, :string(
      $html => { recover => 1, suppress_errors => 1 }
     );
  };
  # TEST
  ok (!$@, 'No exception was thrown.');
  # TEST
  ok ($doc, ' Parsing was successful.');
  my $root = $doc && $doc.documentElement;
  my $val = $root && $root.findvalue('//input[@id="foo"]/@value');
  # TEST
  is ($val, 'working', 'XPath');
}


{
    # 70878
    # HTML_PARSE_NODEFDTD

    SKIP: {
        skip("LibXML version is below 20708", 2) unless ( LibXML::LIBXML_VERSION >= 20708 );

        my $html = q(<body bgcolor='#ffffff' style="overflow: hidden;" leftmargin=0 MARGINWIDTH=0 CLASS="text">);
        my $p = LibXML.new;

        # TEST
        like( $p.parse: :html, :string( $html, {
                    recover => 2,
                    no_defdtd => 1,
                    encoding => 'UTF-8' } ).toStringHTML, qr/^\Q<html>\E/, 'do not add a default DOCTYPE' );

        # TEST
        like ( $p.parse: :html, :string( $html, {
                    recover => 2,
                    encoding => 'UTF-8' } ).toStringHTML, qr/^\Q<!DOCTYPE html\E/, 'add a default DOCTYPE' );
    }
}

=end TODO
