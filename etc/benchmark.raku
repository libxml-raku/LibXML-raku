use LibXML;
use LibXML::Document;
use LibXML::Element;
use XML;
use LibXML::SAX::Handler::XML;

use Bench;

multi sub load('libxml') { LibXML.parse: :$*file; };
multi sub load('xml') { from-xml-file($*file) };
multi sub load('hybrid') {
    my $sax-handler = LibXML::SAX::Handler::XML.new;
    LibXML.parse: :$*file, :$sax-handler;
};

multi sub get-elems(LibXML::Element:D $e) {
    for 1 .. 50 {
        my @elems = $e.getElementsByTagName('files');
    }
}

multi sub get-elems(XML::Element:D $e) {
    for 1 .. 50 {
        my @elems = $e.elements(:TAG<files>);
    }
}

multi sub get-elems-local(LibXML::Element:D $e) {
    for 1 .. 50 {
        my @elems = $e.getElementsByLocalName('files');
    }
}
sub get-elems-native(LibXML::Element:D $e) {
    my $native = $e.native;
    for 1 .. 50 {
        $native.getElementsByTagName('files');
    }
}
multi sub get-attribute(LibXML::Element:D $e) {
    for 1 .. 500 {
       $e.getAttribute('name');
    }
}
multi sub get-attribute-native(LibXML::Element:D $e) {
    my $native = $e.native;
    for 1 .. 500 {
       $native.getAttribute('name');
    }
}
multi sub get-attribute(XML::Element:D $e) {
    for 1 .. 500 {
       $e.attribs<name>;
    }
}

sub MAIN(Str :$*file='etc/libxml2-api.xml', UInt :$*reps = 10) {
    my Bench $b .= new;
    
    my XML::Document $xml-doc = load('xml');
    my LibXML::Document $libxml-doc = load('libxml');
    my XML::Element $xml-root = $xml-doc.root;
    my LibXML::Element $libxml-root = $libxml-doc.root;

    $b.timethese: $*reps, %(
        flat
        <libxml xml hybrid>.map({'00-load.'~$_ => {load($_)} }),
        '01-elems.libxml' => -> { get-elems($libxml-root)},
        '01-elems.libxml-native' => -> { get-elems-native($libxml-root)},
        '01-elems.libxml-local' => -> { get-elems-local($libxml-root)},
        '01-elems.xml' =>  -> { get-elems($xml-root)},
        '02-attribs.libxml' => -> { get-attribute($libxml-root)},
        '02-attribs.libxml-native' => -> { get-attribute-native($libxml-root)},
        '02-attribs.xml' => -> { get-attribute($xml-root)},
    );

}
