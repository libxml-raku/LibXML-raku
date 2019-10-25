use v6;
use LibXML;
use Test;
plan 2;

my $html = q:to/HTML/;
<!DOCTYPE html>
<html>
<body>
<aside class="hello">hello</aside>
<nav>goodbye</nav>
</body>
</html>
HTML

my $parser = LibXML.new;
my $doc = $parser.parse(
    :string($html),
    :recover,
    :suppress-errors,
    :suppress-warnings,
    :html
);

isa-ok $doc, 'LibXML::Document';

my @nodes = $doc.findnodes("//aside[@class='hello']");
ok @nodes > 0;
