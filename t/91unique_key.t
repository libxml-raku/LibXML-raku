use v6;
use Test;
plan 35;

use LibXML;
use LibXML::Config;
use LibXML::Document;
use LibXML::Element;
use LibXML::Namespace;
use LibXML::Node;

LibXML::Config.use-global;

my $xmlstring = q{<foo>bar<foobar/><bar foo="foobar"/><!--foo--><![CDATA[&foo bar]]></foo>};

my LibXML $parser .= new();
my LibXML::Document $doc = $parser.parse: :string( $xmlstring );

my LibXML::Element $foo = $doc.documentElement;

my LibXML::Node @children_1 = $foo.childNodes;
my LibXML::Node @children_2 = $foo.childNodes;

ok(@children_1[0].can('unique-key'), 'unique-key method available')
    or exit -1;

# compare unique keys between all nodes in the above tiny document.
# Different nodes should have different keys; same nodes should have the same keys.
for 0..4 -> $c1 {
    for 0..4 -> $c2 {
        if $c1 == $c2 {
            is(@children_1[$c1].unique-key, @children_2[$c2].unique-key,
                'Key for ' ~ @children_1[$c1].nodeName ~
                ' matches key from same node');
        } else {
            isnt(@children_1[$c1].unique-key, @children_2[$c2].unique-key,
                'Key for ' ~ @children_1[$c1].nodeName ~
                ' does not match key for' ~ @children_2[$c2].nodeName);
        }
    }
}

my LibXML::Namespace $foo_default_ns = $doc.create(LibXML::Namespace, 'foo.com');
my LibXML::Namespace $foo_ns .= new('foo.com','foo');
my LibXML::Namespace $bar_default_ns .= new('bar.com');
my LibXML::Namespace$bar_ns .= new('bar.com','bar');
ok $foo_ns.isSameNode($foo_ns);
nok $foo_ns.isSameNode($bar_ns);
nok $foo_ns.isSameNode($doc);
nok $doc.isSameNode($foo_ns);

is(
    LibXML::Namespace.new('foo.com').unique-key,
    LibXML::Namespace.new('foo.com').unique-key,
    'default foo ns key matches itself'
);


isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('foo.com', 'bar').unique-key,
    q[keys for ns's with different prefixes don't match]
);

isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('foo.com').unique-key,
    q[key for prefixed ns doesn't match key for default ns]
);

isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('bar.com', 'foo').unique-key,
    q[keys for ns's with different URI's don't match]
);

isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('bar.com', 'bar').unique-key,
    q[keys for ns's with different URI's and prefixes don't match]
);
