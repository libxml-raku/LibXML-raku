use Test;
use LibXML::Document;
use LibXML::Config;

plan 4;

my $xml = q:to<XML>;
    <root>
      <elem att="value" />
      Some text
    </root>
    XML

my LibXML::Document $doc-uncached .= parse: :string($xml), :!blanks;

my LibXML::Config $config .= new: :with-cache;
ok $config.with-cache;

my LibXML::Document $doc-cached .= parse: :string($xml), :$config, :!blanks;

subtest 'without caching', {
    nok $doc-uncached.config.with-cache;
    my @nodes1 = $doc-uncached.root.children;
    my @nodes2 = $doc-uncached.root.children;
    nok $doc-uncached.root === $doc-uncached.root;
    nok $doc-uncached.root.doc === $doc-uncached.root.doc;
    nok @nodes1.head === @nodes2.head;
    nok @nodes1.tail === @nodes2.tail;
    nok @nodes1.head.getAttributeNode('att') === @nodes2.head.getAttributeNode('att');
}

subtest 'with caching', {
    ok $doc-cached.config.with-cache;
    ok $doc-cached.root === $doc-cached.root;
    ok $doc-cached.root.doc === $doc-cached.root.doc;
    my @nodes1 = $doc-cached.root.children;
    my @nodes2 = $doc-cached.root.children;
    ok @nodes1.head === @nodes2.head;
    ok @nodes1.tail === @nodes2.tail;
    ok @nodes1.head.getAttributeNode('att') === @nodes2.head.getAttributeNode('att');
}

subtest 'equivalence', {
    my @nodes1 = $doc-cached.root.children;
    my @nodes2 = $doc-uncached.root.children;
    ok @nodes1.head eqv @nodes2.head;
    ok @nodes1.tail eqv @nodes2.tail;
}
