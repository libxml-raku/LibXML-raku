use Test;
plan 11;

# Experimental. This may change without notice.
# Testing the current ability of Raku LibXML to define custom node classes:
# - The custom class must be a subclass of the overridden class
# - It either must be REPR('CPointer') or contain an appropriate 'raw' attribute
# - Best to construct new objects via the DOM. $doc.createElement(...), etc.

use LibXML;
use LibXML::Config;
use LibXML::Enums;
use LibXML::Document;
use LibXML::Element;
use LibXML::Attr;
use LibXML::Raw;

class MyElement is LibXML::Element {
    has Str:D $.my-attr = "something special";
    method nodeValue { 'bazinga' }
}

class MyAttr is LibXML::Attr {
#    submethod TWEAK {
#        isa-ok $.raw, xmlAttr, 'MyAttr $.raw type';
#        ok defined($.raw), 'MyAttr $.raw is defined';
#    }
}

my $config = LibXML::Config.new;
$config.map-class(
    'LibXML::Element' => MyElement,
    LibXML::Attr => MyAttr );

my LibXML::Document:D $doc .= parse: :string(q:to<END>), :$config;
<doc att="42">test</doc>
END

my $root = $doc.getDocumentElement;

isa-ok $root, MyElement, 'parsed elem type';
isa-ok $root.raw, xmlElem, 'parsed element $.raw type';
ok defined($root.raw), 'parsed element $.raw is defined';
is $root.nodeName, 'doc', 'parsed elem name';
is $root.nodeValue, 'bazinga', 'parsed elem value';

my $attr = $root.getAttributeNode("att");

isa-ok $attr, MyAttr, 'element attribute type';
isa-ok $attr.raw, xmlAttr, 'element attribute $.raw type';

my $elem = $doc.createElement('foo');

isa-ok $elem, MyElement, 'created elem type';
is $elem.nodeName, 'foo', 'created elem name';
is $elem.nodeValue, 'bazinga', 'created elem value';

$root.addChild($elem);

is $root.Str, '<doc att="42">test<foo/></doc>', 'serialization sanity';
