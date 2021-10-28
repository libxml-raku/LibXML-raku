use v6;
use Test;
plan 16;

use LibXML;
use LibXML::Enums;
use LibXML::Node;
use LibXML::Node::List;
use LibXML::Node::Set;
use LibXML::HashMap;

my $dom = LibXML.parse: :string(data());

subtest 'from childNodes()', {
    my LibXML::Node::List $nodelist = $dom.documentElement.childNodes;
    # 0 is #text
    is $nodelist[1].nodeName, 'BBB', 'item is 0-indexed';
    is $nodelist<CCC>[0].nodeName, 'CCC', 'AT-KEY sanity';
    is $nodelist.head.nodeType, +XML_TEXT_NODE;
    is $nodelist.tail.nodeType, +XML_TEXT_NODE;
    my LibXML::HashMap[LibXML::Node::Set] $hash = $nodelist.Hash;
    is $hash.keys.sort.join(','), 'BBB,CCC,DDD,text()';
}

subtest 'from findnodes()', {
    my LibXML::Node @nodes = $dom.findnodes('//BBB');

    is +@nodes, 5, 'node count';

    my LibXML::Node::Set $nodeset = $dom.findnodes('//BBB');
    is $nodeset.size, 5, 'size()';
    is $nodeset.Str, '<BBB>OK</BBB><BBB/><BBB/><BBB/><BBB>NOT OK</BBB>', 'Str()';
    is $nodeset<BBB>[0].textContent, 'OK', 'AT-KEY sanity';
    is $nodeset.string-value, "OK", 'string-value()'; # first node in set

    is $nodeset.to-literal, "OKNOT OK", 'to-literal()';

    is $nodeset.to-literal(:delimiter<,>), "OK,,,,NOT OK", 'to-literal(:$delimiter)';

    is-deeply [$nodeset.to-literal(:list)], ['OK', '', '', '', 'NOT OK'], 'to-literal(:list)';

    is $dom.findvalue("//BBB"), "OKNOT OK", 'findvalue()';

    isa-ok $dom.find("1 and 2"), Bool, 'find --> Bool';

    isa-ok $dom.find("'Hello World'"), Str, 'find --> Str';

    isa-ok $dom.find("32 + 13"), Num, 'find --> Num';

    isa-ok $dom.find("//CCC"), "LibXML::Node::Set", 'find --> LibXML::Node::Set';
}

skip("port remaining tests", 14);
    
=begin TODO
my LibXML::Node::List $numbers .= new(1..10);
my $oddify  = sub { $_ + ($_%2?0:9) }; # add 9 to even numbers
my @map = $numbers.map($oddify);

is(scalar(@map), 10, 'map called in list context returns list');

is(join('|',@map), '1|11|3|13|5|15|7|17|9|19', 'mapped data correct');

my $map = $numbers.map($oddify);

isa_ok($map => 'LibXML::NodeList', '$map');

my @map2 = $map.map(sub { $_ > 10 ? () : ($_,$_,$_) });

is(join('|',@map2), '1|1|1|3|3|3|5|5|5|7|7|7|9|9|9', 'mapping can add/remove nodes');

my @grep = $numbers.grep(sub {$_%2});
my $grep = $numbers.grep(sub {$_%2});

is(join('|',@grep), '1|3|5|7|9', 'grep works');

isa_ok($grep => 'LibXML::NodeList', '$grep');

my LibXML::Node::List $shuffled .= new(qw/1 4 2 3 6 5 9 7 8 10/);
my @alphabetical = $shuffled.sort(sub { my ($a, $b) = @_; $a cmp $b });
my @numeric      = $shuffled.sort(sub { my ($a, $b) = @_; $a <=> $b });

is(join('|',@alphabetical), '1|10|2|3|4|5|6|7|8|9', 'sort works 1');

is(join('|',@numeric), '1|2|3|4|5|6|7|8|9|10', 'sort works 2');

my LibXML::Node::List $reverse .= new;
my $return  = $numbers.foreach( sub { $reverse.unshift($_) } );

is(
  blessed_refaddr($return),
  blessed_refaddr($numbers),
  'foreach returns $self',
  );

is(join('|',@$reverse), '10|9|8|7|6|5|4|3|2|1', 'foreach works');

my $biggest  = $shuffled.reduce(sub { $_[0] > $_[1] ? $_[0] : $_[1] }, -1);
my $smallest = $shuffled.reduce(sub { $_[0] < $_[1] ? $_[0] : $_[1] }, 9999);

is($biggest, 10, 'reduce works 1');

is($smallest, 1, 'reduce works 2');

my @reverse = $numbers.reverse;

is(join('|',@reverse), '10|9|8|7|6|5|4|3|2|1', 'reverse works');

=end TODO

sub data {
    q:to<__DATA__>;
    <AAA>
    <BBB>OK</BBB>
    <CCC/>
    <BBB/>
    <DDD><BBB/></DDD>
    <CCC><DDD><BBB/><BBB>NOT OK</BBB></DDD></CCC>
    </AAA>
    __DATA__
}
