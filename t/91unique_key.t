use v6;
use Test;
plan 31;

use LibXML;
use LibXML::Document;
use LibXML::Element;
use LibXML::Node;
my $xmlstring = q{<foo>bar<foobar/><bar foo="foobar"/><!--foo--><![CDATA[&foo bar]]></foo>};

my LibXML $parser .= new();
my LibXML::Document $doc = $parser.parse: :string( $xmlstring );

my  LibXML::Element $foo = $doc.documentElement;

# TEST:$num_children=5;
my LibXML::Node @children_1 = $foo.childNodes;
my LibXML::Node @children_2 = $foo.childNodes;

ok(@children_1[0].can('unique-key'), 'unique-key method available')
    or exit -1;

# compare unique keys between all nodes in the above tiny document.
# Different nodes should have different keys; same nodes should have the same keys.
for 0..4 -> $c1 {
    for 0..4 -> $c2 {
        if $c1 == $c2 {
            # TEST*$num_children
            is(@children_1[$c1].unique-key, @children_2[$c2].unique-key,
                'Key for ' ~ @children_1[$c1].nodeName ~
                ' matches key from same node');
        } else {
            # TEST*($num_children)*($num_children-1)
            isnt(@children_1[$c1].unique-key, @children_2[$c2].unique-key,
                'Key for ' ~ @children_1[$c1].nodeName ~
                ' does not match key for' ~ @children_2[$c2].nodeName);
        }
    }
}

my $foo_default_ns = LibXML::Namespace.new('foo.com');
my $foo_ns = LibXML::Namespace.new('foo.com','foo');
my $bar_default_ns = LibXML::Namespace.new('bar.com');
my $bar_ns = LibXML::Namespace.new('bar.com','bar');

# TEST
is(
    LibXML::Namespace.new('foo.com').unique-key,
    LibXML::Namespace.new('foo.com').unique-key,
    'default foo ns key matches itself'
);

# TEST
isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('foo.com', 'bar').unique-key,
    q[keys for ns's with different prefixes don't match]
);

# TEST
isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('foo.com').unique-key,
    q[key for prefixed ns doesn't match key for default ns]
);

# TEST
isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('bar.com', 'foo').unique-key,
    q[keys for ns's with different URI's don't match]
);

# TEST
isnt(
    LibXML::Namespace.new('foo.com', 'foo').unique-key,
    LibXML::Namespace.new('bar.com', 'bar').unique-key,
    q[keys for ns's with different URI's and prefixes don't match]
);
