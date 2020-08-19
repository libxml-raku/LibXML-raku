use v6;
use LibXML;
use Test;
plan 7;

my $parser = LibXML.new;
my $file = 'test/xinclude/test.xml';
{
  $parser.expand-xinclude = False;
  $parser.expand-entities = True;
  unlike($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = True;
  $parser.expand-entities = False;
  unlike($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = True;
  $parser.expand-entities = True;
   like($parser.parse(:$file).Str, /'IT WORKS'/, ' TODO : Add test name');
}
{
  $parser.expand-xinclude = False;
  my $doc = $parser.parse: :$file;
  ok( $doc.process-xincludes(:!expand-entities), ' TODO : Add test name' );
  unlike($doc.Str, /'IT WORKS'/, ' TODO : Add test name' );
}
{
  my $doc = $parser.parse :$file;
  ok( $doc.process-xincludes(:expand-entities), ' TODO : Add test name' );
  like($doc.Str, /'IT WORKS'/, ' TODO : Add test name' );
}
