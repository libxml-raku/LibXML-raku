use v6;
use Test;
use LibXML;
use LibXML::Document;
use LibXML::Node;
use LibXML::Node::Set;

class dummySelectorHandler {
    # one hard-coded rule adapted from the CSS::Selector::To::XPath test suite
    method selector-to-xpath('li.bar') {"//li[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]"}
}

my LibXML::Document $doc = LibXML.parse: :string(q:to<\_(ツ)_/>);
      <ul>
        <li><a href="foo.html">bar</a></li>
        <li class="bar baz"><a href="foo.html">baz</a></li>
        <li class="bar"><a href="foo.html">baz</a></li>
      </ul>
\_(ツ)_/

dies-ok {$doc.querySelector('li.bar')}, 'query selection before configuration - dies';

my List $expected = ('<li class="bar baz"><a href="foo.html">baz</a></li>',
                     '<li class="bar"><a href="foo.html">baz</a></li>');

$doc.query-handler = dummySelectorHandler.new;

my LibXML::Node:D $node = $doc.querySelector('li.bar');
is $node.Str, $expected[0];

my LibXML::Node::Set:D $node-set = $doc.querySelectorAll('li.bar');
is $node-set.map(*.Str), $expected;

done-testing();

