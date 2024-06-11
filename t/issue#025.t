use v6;
use LibXML;
use LibXML::Document;
use Test;
plan 1;

my $html = q:to/HTML/;
<!DOCTYPE html>
<html>
<body>
<aside class="hello">hello</aside>
<nav>goodbye</nav>
</body>
</html>
HTML

my LibXML $parser .= new;
my LibXML::Document:D $doc = $parser.parse(
    :string($html),
    :recover,
    :suppress-errors,
    :suppress-warnings,
    :html
);

my @nodes = $doc.findnodes("//aside[@class='hello']");
ok @nodes > 0;
