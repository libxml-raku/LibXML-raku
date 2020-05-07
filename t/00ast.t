use v6;
use Test;
use LibXML;
use LibXML::Element;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Item :&ast-to-xml;

LibXML.config.keep-blanks-default = False;
my LibXML::Element $elem .= new('Test');
$elem.setAttribute('foo', 'bar');
$elem.appendText('Some text.');
$elem.setNamespace("urn:mammals", "mam");
is-deeply $elem.properties[0].ast, 'foo' => 'bar';
is-deeply $elem.namespaces[0].ast, 'xmlns:mam' => 'urn:mammals';
is-deeply $elem.children[0].ast, 'Some text.';
is-deeply $elem.ast, 'mam:Test' => ['xmlns:mam' => 'urn:mammals', :foo<bar>, 'Some text.'];

$elem = ast-to-xml($elem.ast);
is-deeply $elem.ast, 'mam:Test' => ['xmlns:mam' => 'urn:mammals', :foo<bar>, 'Some text.'];

my $frag-ast = ['#comment' => ' testing ', :species["Camelid"], "xxx", '&foo' => [], ];
my LibXML::DocumentFragment:D $frag = ast-to-xml($frag-ast);
is $frag, '<!-- testing --><species>Camelid</species>xxx&foo;';
is-deeply $frag.ast, '#fragment' => $frag-ast;

my LibXML::Document $doc .= parse: :file<example/dromeds.xml>;
is-deeply $doc.ast, "#xml"
                        => [
                            :dromedaries[
                                     :species[:name<Camel>, :humps["1 or 2"], :disposition["Cranky"]],
                                     :species[:name<Llama>, :humps["1 (sort of)"], :disposition["Aloof"]],
                                     :species[:name<Alpaca>, :humps["(see Llama)"], :disposition["Friendly"]]
                                 ]
                        ];

$doc .= parse: :file<example/ns.xml>;

my $dromedaries = [
    :xmlns("urn:camels"),
    "xmlns:mam" => "urn:mammals",
    :species["Camelid"],
    "mam:legs" => ["xmlns:a" => "urn:a",
                   "xml:lang" => "en",
                   :yyy<zzz>,
                   "a:xxx" => "foo", "4"]
];

is-deeply $doc<dromedaries><species>.ast, (:species['Camelid'], );
is-deeply $doc.ast, "#xml" => [ :$dromedaries ];

$doc<dromedaries><species>[0].replaceNode: ast-to-xml('#comment' => 'youza');
is $doc<dromedaries><comment()>, '<!--youza-->';

done-testing;
