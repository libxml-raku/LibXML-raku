use LibXML;
use Test;
plan 7;

# tests for bug #24953: External entities not expanded in included file (XInclude)

my $parser = LibXML.new;
my $file = 'test/xinclude/test.xml';
{
  $parser.expand-xinclude = False;
  $parser.expand-entities = True;
  # TEST
  unlike($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = True;
  $parser.expand-entities = False;
  # TEST
  unlike($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = True;
  $parser.expand-entities = True;
  # TEST
   like($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = False;
  my $doc = $parser.parse: :$file;
  # TEST
  ok( $doc.process-xincludes(:!expand-entities), ' TODO : Add test name' );
  # TEST
  unlike($doc.Str, /'IT WORKS'/, ' TODO : Add test name' );
}
{
  my $doc = $parser.parse :$file;
  # TEST
  ok( $doc.process-xincludes(:expand-entities), ' TODO : Add test name' );
  # TEST
  like($doc.Str, /'IT WORKS'/, ' TODO : Add test name' );
}
