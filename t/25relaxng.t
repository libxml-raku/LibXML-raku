use v6;

use Test;
use LibXML;
use LibXML::RelaxNG;

plan 13;

if LibXML.parser-version < v20.51.0 {
   skip-rest 'Skip No RNG Support compiled';
   exit;
}

sub slurp(Str $_) { .IO.slurp }

my $xmlparser = LibXML.new();

my $file         = "test/relaxng/schema.rng";
my $badfile      = "test/relaxng/badschema.rng";
my $validfile    = "test/relaxng/demo.xml";
my $invalidfile  = "test/relaxng/invaliddemo.xml";
my $demo4        = "test/relaxng/demo4.rng";

diag "# 1 parse schema from a file\n";
{
    my $rngschema = LibXML::RelaxNG.new( location => $file );
    # TEST
    ok ( $rngschema, ' TODO : Add test name' );
}; skip("Port remaining tests", 12);
=begin TODO

    eval { $rngschema = LibXML::RelaxNG.new( location => $badfile ); };
    # TEST
    ok( $@, ' TODO : Add test name' );
}

print "# 2 parse schema from a string\n";
{
    my $string = slurp($file);

    my $rngschema = LibXML::RelaxNG.new( string => $string );
    # TEST
    ok ( $rngschema, ' TODO : Add test name' );

    $string = slurp($badfile);

    eval { $rngschema = LibXML::RelaxNG.new( string => $string ); };
    # TEST
    ok( $@, ' TODO : Add test name' );
}

print "# 3 parse schema from a document\n";
{
    my $doc       = $xmlparser.parse: :file( $file );
    my $rngschema = LibXML::RelaxNG.new( DOM => $doc );
    # TEST
    ok ( $rngschema, ' TODO : Add test name' );

    $doc       = $xmlparser.parse: :file( $badfile );
    eval { $rngschema = LibXML::RelaxNG.new( DOM => $doc ); };
    # TEST
    ok( $@, ' TODO : Add test name' );
}

print "# 4 validate a document\n";
{
    my $doc       = $xmlparser.parse: :file( $validfile );
    my $rngschema = LibXML::RelaxNG.new( location => $file );

    my $valid = 0;
    eval { $valid = $rngschema.validate( $doc ); };
    # TEST
    is( $valid, 0, ' TODO : Add test name' );

    $doc       = $xmlparser.parse: :file( $invalidfile );
    $valid     = 0;
    eval { $valid = $rngschema.validate( $doc ); };
    # TEST
    ok ( $@, ' TODO : Add test name' );
}

print "# 5 re-validate a modified document\n";
{
  my $rng = LibXML::RelaxNG.new(location => $demo4);
  my $seed_xml = <<'EOXML';
<?xml version="1.0" encoding="UTF-8"?>
<root/>
EOXML

  my $doc = $xmlparser.parse_string($seed_xml);
  my $rootElem = $doc.documentElement;
  my $bogusElem = $doc.createElement('bogus-element');

  eval{$rng.validate($doc);};
  # TEST
  ok ($@, ' TODO : Add test name');

  $rootElem.setAttribute('name', 'rootElem');
  eval{ $rng.validate($doc); };
  # TEST
  ok (!$@, ' TODO : Add test name');

  $rootElem.appendChild($bogusElem);
  eval{$rng.validate($doc);};
  # TEST
  ok ($@, ' TODO : Add test name');

  $bogusElem.unlinkNode();
  eval{$rng.validate($doc);};
  # TEST
  ok (!$@, ' TODO : Add test name');

  $rootElem.removeAttribute('name');
  eval{$rng.validate($doc);};
  # TEST
  ok ($@, ' TODO : Add test name');

}

=end TODO
