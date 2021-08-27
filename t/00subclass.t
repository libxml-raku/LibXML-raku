use Test;
plan 11;

# Experimental. This may change without notice.
# Testing the current ability of Raku LibXML to define custom node classes:
# - The custom class must be a subclass of the overridden class
# - It either must be REPR('CPointer') or contain an appropriate 'raw' attribute
# - Best to construct new obects via the DOM. $doc.createElement(...), etc.

use LibXML;
use LibXML::Config;
use LibXML::Enums;
use LibXML::Document;
use LibXML::Element;

class MyElement is LibXML::Element {
    use LibXML::Raw;
    submethod TWEAK(:$raw) {
        isa-ok $raw, xmlElem, 'TWEAK';
        ok defined($raw), 'TWEAK';
    }
    has xmlElem $.raw;
    method nodeValue { 'bazinga' }
}

@LibXML::Config::ClassMap[XML_ELEMENT_NODE] = MyElement;

my LibXML::Document $doc .= parse: :string(q:to<END>);
<doc>test</doc>
END

my $root = $doc.getDocumentElement;

isa-ok $root, MyElement, 'parsed elem type';
is $root.nodeName, 'doc', 'parsed elem name';
is $root.nodeValue, 'bazinga', 'parsed elem value';

my $elem = $doc.createElement('foo');

isa-ok $elem, MyElement, 'created elem type';
is $elem.nodeName, 'foo', 'created elem name';
is $elem.nodeValue, 'bazinga', 'created elem value';

$root.addChild($elem);

is $root.Str, '<doc>test<foo/></doc>', 'serialization sanity';
