use LibXML;
use LibXML::Node;
use LibXML::Document;
use LibXML::Element;
use XML;
use LibXML::SAX::Handler::XML;
use LibXML::XPath::Expression;

use Bench;

sub traverse-elems($_) {
    traverse-elems($_) for .elements;
}

sub traverse-kids($_) {
    traverse-kids($_) for .childNodes;
}

multi sub get-elems(LibXML::Element:D $e) {
    my @elems = $e.getElementsByTagName('files');
}

multi sub get-elems(XML::Element:D $e) {
    my @elems = $e.elements(:TAG<files>);
}

multi sub get-elems-local(LibXML::Element:D $e) {
    my @elems = $e.getElementsByLocalName('files');
}
multi sub get-elems-assoc(LibXML::Element:D $e) {
    my @elems = $e<files>.list;
}
sub get-elems-native(LibXML::Element:D $e) {
    $e.native.getElementsByTagName('files');
}
sub find-elems(LibXML::Element:D $e) {
    $e.find($*kids-expr);
}
sub get-children(LibXML::Element:D $e) {
    $e.childNodes
}
sub get-children-array(LibXML::Element:D $e) {
    $e.childNodes.Array;
}
sub get-children-native(LibXML::Element:D $e) {
    $e.native.children;
}
multi sub get-attribute(LibXML::Element:D $e) {
    for 1 .. 5 {
       $e.getAttribute('name');
    }
}
multi sub get-attribute-native(LibXML::Element:D $e) {
    my $native = $e.native;
    for 1 .. 5 {
       $native.getAttribute('name');
    }
}
multi sub get-attribute(XML::Element:D $e) {
    for 1 .. 5 {
       $e.attribs<name>;
    }
}

multi sub unbox($e) {
    for 1 .. 50 {
       $e.unbox;
    }
}

multi sub box($raw) {
    for 1 .. 50 {
       LibXML::Element.box($raw);
    }
}

multi sub keep($e, $raw) {
    for 1 .. 50 {
       $e.keep: $raw;
    }
}

sub MAIN(Str :$*file='etc/libxml2-api.xml', UInt :$*reps = 1000) {
    my Bench $b .= new;
    
    my XML::Document $xml;
    my LibXML::Document $libxml;
    my XML::Element $xml-root;
    my LibXML::Element $libxml-root;
    my $raw;

    $b.timethese: 1, %(
        '00-load.libxml' => {
            $libxml = LibXML.parse: :$*file, :!blanks;
            $libxml-root = $libxml.root;
            $raw = $libxml-root.unbox;
        },
        '00-load.xml' => {
            $xml = from-xml-file($*file);
            $xml-root = $xml.root;
        },
        '00-hybrid' => {
            my $sax-handler = LibXML::SAX::Handler::XML.new;
            LibXML.parse: :$*file, :$sax-handler;
        },
        '01-traverse-elems.xml' => { traverse-elems($xml-root) },
        '01-traverse-elems.libxml' => { traverse-elems($libxml-root) },
        '01-traverse-kids.libxml' => { traverse-kids($libxml-root) },
    );

    my LibXML::XPath::Expression $*kids-expr .= compile("descendant::*");

    $b.timethese: $*reps, %(
        '02-elems.libxml' => -> { get-elems($libxml-root)},
        '02-children.libxml' => -> { get-children($libxml-root)},
        '02-children-array.libxml' => -> { get-children-array($libxml-root)},
        '02-elems.libxml-native' => -> { get-elems-native($libxml-root)},
        '02-find.libxml' => -> { find-elems($libxml-root)},
        '02-children.libxml-native' => -> { get-children-native($libxml-root)},
        '02-elems.libxml-local' => -> { get-elems-local($libxml-root)},
        '02-elems.libxml-assoc' => -> { get-elems-assoc($libxml-root)},
        '03-elems.xml' =>  -> { get-elems($xml-root)},
        '03-attribs.libxml' => -> { get-attribute($libxml-root)},
        '03-attribs.libxml-native' => -> { get-attribute-native($libxml-root)},
        '03-attribs.xml' => -> { get-attribute($xml-root)},
        '04-box' => { box($raw) },
        '04-unbox' => { unbox($libxml-root) },
        '04-keep' => { keep($libxml-root, $raw) },
    );

}
