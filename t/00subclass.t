use Test;
plan 2;

# Experimental. This may change without notice.
# Testing the current ability of Raku LibXML to define custom node classes:

use LibXML;
use LibXML::Config;
use LibXML::Enums;
use LibXML::Document;
use LibXML::Element;
use LibXML::Attr;
use LibXML::Raw;
use LibXML::Types;
use OO::Monitors;

class MyElement is LibXML::Element {
    has Str:D $.my-attr = "something special";
    method nodeValue { 'bazinga' }
}

class MyElement::Foo is MyElement {
    method bar {
        self.getAttribute('bar')
    }
}

class MyAttr is LibXML::Attr {
#    submethod TWEAK {
#        isa-ok $.raw, xmlAttr, 'MyAttr $.raw type';
#        ok defined($.raw), 'MyAttr $.raw is defined';
#    }
}

subtest "Basics" => {
    plan 11;
    my $config = LibXML::Config.new;
    $config.map-class(
        'LibXML::Element' => MyElement,
        (LibXML::Attr) => MyAttr );

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
}

subtest "By Element Type" => {
    plan 4;
    my monitor MyConfig is LibXML::Config {
        proto method class-from(|) {*}
        multi method class-from(::?CLASS:D: anyNode:D $raw) is raw {
            $raw.getNodeName eq 'foo' ?? MyElement::Foo !! nextsame
        }
        multi method class-from(|) is raw { nextsame }
    }

    my $config = MyConfig.new;
    $config.map-class('LibXML::Element' => MyElement);
    my LibXML::Document:D $doc .= parse: :string(q:to<END>), :$config;
    <doc><foo bar="The Answer" /></doc>
    END

    isa-ok $doc.config, MyConfig, "document config class";

    my $root = $doc.getDocumentElement;

    isa-ok $root, MyElement, "root element";
    my $foo = $root.findnodes(q«//foo»).head;
    isa-ok $foo, MyElement::Foo, "subelement type";
    is $foo.bar, "The Answer", "attribute reader method";
}