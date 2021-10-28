use v6;
use LibXML;
use Test;
plan 7;

my LibXML $parser .= new;
my $file = 'test/xinclude/test.xml';
{
    $parser.expand-xinclude = False;
    $parser.expand-entities = True;
    unlike $parser.parse(:$file).Str, /'IT WORKS'/, 'parse: :!expand-xinclude, :expand-entities';;
}
{
    $parser.expand-xinclude = True;
    $parser.expand-entities = False;
    unlike $parser.parse(:$file).Str, /'IT WORKS'/, 'parse: :expand-xinclude, :!expand-entities';;
}
{
    $parser.expand-xinclude = True;
    $parser.expand-entities = True;
    like $parser.parse(:$file).Str, /'IT WORKS'/, 'parse: :expand-xinclude, :expand-entities';;
}
{
    $parser.expand-xinclude = False;
    my $doc = $parser.parse: :$file;
    ok  $doc.process-xincludes(:!expand-entities), 'process-xincludes: :!expand-xinclude, :!expand-entities';
    unlike $doc.Str, /'IT WORKS'/, 'process-xincludes: :!expand-xinclude, :!expand-entities';
}
{
    my $doc = $parser.parse :$file;
    ok $doc.process-xincludes(:expand-entities), 'process-xincludes: :!expand-xinclude, :expand-entities';
    like $doc.Str, /'IT WORKS'/,  'process-xincludes: :!expand-xinclude, :expand-entities';
}
