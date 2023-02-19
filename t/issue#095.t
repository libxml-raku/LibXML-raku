use v6;
use LibXML;
use LibXML::Element;
use Test;
plan 1;

my $html = q:to/XML/;
<body>
<anElem/>
Some text
</body>
XML

my LibXML $parser .= new;
my $doc = $parser.parse(
    :string($html),
    :!blanks,
);

throws-like { for $doc.root.childNodes -> LibXML::Element $re {} }, X::TypeCheck::Binding::Parameter;
