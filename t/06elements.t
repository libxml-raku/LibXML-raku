# this test checks the DOM element and attribute interface of XML::LibXML

use v6;
use Test;
plan 10;

use LibXML;
use LibXML::Document;
use LibXML::Enums;

my $foo       = "foo";
my $bar       = "bar";
my $nsURI     = "http://foo";
my $prefix    = "x";
my $attname1  = "A";
my $attvalue1 = "a";
my $attname2  = "B";
my $attvalue2 = "b";
my $attname3  = "C";

my @badnames= ("1A", "<><", "&", "-:");

subtest 'bound node', {
    my $doc = LibXML::Document.new();
    my $elem = $doc.createElement( $foo );
    ok $elem.defined;
    is $elem.tagName, $foo;

    for @badnames -> $name {
        dies-ok { $elem.setNodeName( $name ); }, "setNodeName throws an exception for $name";
    }

    subtest 'attributes', {
        $elem.setAttribute( $attname1, $attvalue1 );
        ok $elem.hasAttribute($attname1);
        is $elem.getAttribute($attname1), $attvalue1;

        my $attr = $elem.getAttributeNode($attname1);
        ok $attr.defined;
        is $attr.name, $attname1;
        is $attr.value, $attvalue1;

        $attr = $elem.attribute($attname1);
        ok $attr.defined;
        is $attr.name, $attname1;
        is $attr.value, $attvalue1;

        $elem.setAttribute( $attname1, $attvalue2 );
        is $elem.getAttribute($attname1), $attvalue2;
        is $attr.value, $attvalue2;

        my $attr2 = $doc.createAttribute($attname2, $attvalue1);
        ok $attr2.defined;

        $elem.setAttributeNode($attr2);
        ok $elem.hasAttribute($attname2);
        is $elem.getAttribute($attname2),$attvalue1;

        my $tattr = $elem.getAttributeNode($attname2);
        ok $tattr.isSameNode($attr2);

        $elem.setAttribute($attname2, "");
        ok $elem.hasAttribute($attname2);
        is $elem.getAttribute($attname2), "";

        $elem.setAttribute($attname3, "");
        ok $elem.hasAttribute($attname3);
        is $elem.getAttribute($attname3), "";

        for @badnames -> $name {
            dies-ok {$elem.setAttribute( $name, "X" );}, "setAttribute throws an exception for '$name'";
        }
    }

    subtest 'namespace attributes', {
        $elem.setAttributeNS( $nsURI, $prefix ~ ":" ~ $foo, $attvalue2 );
        ok $elem.hasAttributeNS( $nsURI, $foo );
        ok ! $elem.hasAttribute( $foo );
        ok $elem.hasAttribute( $prefix~":"~$foo );

        my $tattr = $elem.getAttributeNodeNS( $nsURI, $foo );
        ok $tattr.defined;
        is $tattr.name, $foo;
        is $tattr.nodeName, $prefix~":"~$foo;
        is $tattr.value, $attvalue2;

        $elem.removeAttributeNode( $tattr );
        nok $elem.hasAttributeNS($nsURI, $foo);
    }

    subtest 'empty NS', {
        $elem.setAttributeNS( '', $foo, $attvalue2 );
        ok $elem.hasAttribute( $foo );
        my $tattr = $elem.getAttributeNode( $foo );
        ok $tattr.defined;
        is $tattr.name, $foo;
        is $tattr.nodeName, $foo;
        ok !$tattr.namespaceURI.defined, 'namespaceURI N/A is not defined';
        is $tattr.value, $attvalue2;

        is-deeply $elem.hasAttribute($foo), True;
        is-deeply $elem.hasAttributeNS(Str, $foo), True,
        is-deeply $elem.hasAttributeNS('', $foo), True;

        $elem.removeAttributeNode( $tattr );
        nok $elem.hasAttributeNS('', $foo);
        nok $elem.hasAttributeNS(Str, $foo);
    }

    subtest 'node based functions', {
        my $e2 = $doc.createElement($foo);
        $doc.setDocumentElement($e2);
        my $nsAttr = $doc.createAttributeNS( $nsURI~".x", $prefix~":"~$foo, $bar);
        ok $nsAttr.defined;
        $elem.setAttributeNodeNS($nsAttr);
        ok $elem.hasAttributeNS($nsURI~".x", $foo);
        $elem.removeAttributeNS( $nsURI~".x", $foo);
        nok $elem.hasAttributeNS($nsURI~".x", $foo);

        $elem.setAttributeNS( $nsURI, $prefix ~ ":"~ $attname1, $attvalue2 );

        $elem.removeAttributeNS("",$attname1);


        nok $elem.hasAttribute($attname1);
        ok $elem.hasAttributeNS($nsURI,$attname1);

        for @badnames -> $name {
            dies-ok {$elem.setAttributeNS( Str, $name, "X" );}, "setAttributeNS throws an exception for '$name'";
        }
    }
}

subtest 'unbound node', {
    my $elem = LibXML::Element.new: :name($foo);
    ok $elem.defined;
    is $elem.tagName, $foo;

    $elem.setAttribute( $attname1, $attvalue1 );
    ok $elem.hasAttribute($attname1);
    is $elem.getAttribute($attname1), $attvalue1;

    my $attr = $elem.getAttributeNode($attname1);
    ok $attr.defined;
    is $attr.name, $attname1;
    is $attr.value, $attvalue1;

    $elem.setAttributeNS( $nsURI, $prefix ~ ":"~ $foo, $attvalue2 );
    ok $elem.hasAttributeNS( $nsURI, $foo );

    my $tattr = $elem.getAttributeNodeNS( $nsURI, $foo );
    ok $tattr.defined;
    is $tattr.name, $foo;
    is $tattr.nodeName, $prefix~ ":" ~$foo;
    is $tattr.value, $attvalue2;

    $elem.removeAttributeNode( $tattr );
    nok $elem.hasAttributeNS($nsURI, $foo);
}


subtest 'namespace switching', {
    my $elem = LibXML::Element.new: :name($foo);
    ok $elem.defined;

    my $doc = LibXML::Document.new();
    my $e2 = $doc.createElement($foo);
    $doc.setDocumentElement($e2);
    my $nsAttr = $doc.createAttributeNS( $nsURI, $prefix ~ ":"~ $foo, $bar);
    ok $nsAttr.defined;

    $elem.setAttributeNodeNS($nsAttr);
    ok $elem.hasAttributeNS($nsURI, $foo);

    nok defined($nsAttr.ownerDocument);
}

subtest 'default Namespace and Attributes', {
    my $doc  = LibXML::Document.new();
    my $elem = $doc.createElementNS( "foo", "root" );
    $doc.setDocumentElement( $elem );

    $elem.setNamespace( "foo", "bar" );

    $elem.setAttributeNS( "foo", "x:attr",  "test" );
    $elem.setAttributeNS( Str, "attr2",  "test" );


    is $elem.getAttributeNS( "foo", "attr" ), "test";
    is $elem.getAttributeNS( "", "attr2" ), "test";

    # actually this doesn't work correctly with libxml2 <= 2.4.23
    $elem.setAttributeNS( "foo", "attr2",  "bar" );
    is $elem.getAttributeNS( "foo", "attr2" ), "bar";
}

subtest 'Normalization on an Element node', {
    my $doc = LibXML::Document.new();
    my $t1 = $doc.createTextNode( "bar1" );
    my $t2 = $doc.createTextNode( "bar2" );
    my $t3 = $doc.createTextNode( "bar3" );
    my $e  = $doc.createElement("foo");
    my $e2 = $doc.createElement("bar");
    $e.appendChild( $e2 );
    $e.appendChild( $t1 );
    $e.appendChild( $t2 );
    $e.appendChild( $t3 );

    my @cn = $e.childNodes;

    # this is the correct behaviour for DOM. the nodes are still
    # referred
    is +@cn , 4;

    $e.normalize;

    @cn = $e.childNodes;
    is +@cn, 2;

    nok defined($t2.parentNode);
    nok defined($t3.parentNode);
}

subtest 'Normalization on a Document node', {
    my $doc = LibXML::Document.new();
    my $t1 = $doc.createTextNode( "bar1" );
    my $t2 = $doc.createTextNode( "bar2" );
    my $t3 = $doc.createTextNode( "bar3" );
    my $e  = $doc.createElement("foo");
    my $e2 = $doc.createElement("bar");
    $doc.setDocumentElement($e);
    $e.appendChild( $e2 );
    $e.appendChild( $t1 );
    $e.appendChild( $t2 );
    $e.appendChild( $t3 );

    my @cn = $e.childNodes;

    # this is the correct behaviour for DOM. the nodes are still
    # referred
    is +@cn, 4;

    $doc.normalize;

    @cn = $e.childNodes;
    is +@cn, 2;


    nok defined($t2.parentNode);
    nok defined($t3.parentNode);
}

subtest 'LibXML extensions', {
    my $plainstring = "foo";
    my $stdentstring= "$foo & this";

    my $doc = LibXML::Document.new();
    my $elem = $doc.createElement( $foo );
    $doc.setDocumentElement( $elem );

    $elem.appendText( $plainstring );
    is $elem.string-value , $plainstring, 'appendText, initial';

    $elem.appendText( $stdentstring );
    is $elem.string-value , $plainstring ~ $stdentstring, 'appendText, again';

    $elem.appendTextChild( "foo");
    my LibXML::Element $text-child = $elem.appendTextChild( "foo" => "foo&bar" );
    is $text-child, '<foo>foo&amp;bar</foo>';
    is $text-child.name, 'foo';
    is $text-child.textContent, "foo&bar";
    ok $text-child.parent.isSame($elem);

    my @cn = $elem.childNodes;
    ok @cn;
    is +@cn, 3;
    nok @cn[1].hasChildNodes;
    ok @cn[2].hasChildNodes;
}

subtest 'LibXML::Attr nodes', {
    my $dtd = q:to<EOF>;
    <!DOCTYPE root [
    <!ELEMENT root EMPTY>
    <!ATTLIST root fixed CDATA  #FIXED "foo">
    <!ATTLIST root a:ns_fixed CDATA  #FIXED "ns_foo">
    <!ATTLIST root name NMTOKEN #IMPLIED>
    <!ENTITY ent "ENT">
    ]>
    EOF
    my $ns = 'urn:xx';
    my $xml_nons = '<root foo="&quot;bar&ent;&quot;" xmlns:a="%s"/>'.sprintf($ns);
    my $xml_ns = '<root xmlns="%s" xmlns:a="%s" foo="&quot;bar&ent;&quot;"/>'.sprintf($ns, $ns);

    for ($xml_nons, $xml_ns) -> $xml {
        my $parser = LibXML.new;
        $parser.complete-attributes = False;
        $parser.expand-entities = False;
        my $doc = $parser.parse: :string($dtd ~ $xml);

        ok $doc.defined;
        my $root = $doc.getDocumentElement;
        subtest 'getAttributeNode', {
            my $attr = $root.getAttributeNode('foo');
            ok $attr.defined;
            isa-ok $attr, 'LibXML::Attr';
            ok $root.isSameNode($attr.ownerElement);
            is $attr.value, '"barENT"';
            is $attr.serializeContent, '&quot;bar&ent;&quot;';
            is $attr.gist, 'foo="&quot;bar&ent;&quot;"';
        }
        subtest 'getAttributeNodeNS', {
            my $attr = $root.getAttributeNodeNS(Str,'foo');
            ok $attr.defined;
            isa-ok $attr, 'LibXML::Attr';
            ok $root.isSameNode($attr.ownerElement);
            is $attr.value, '"barENT"';
        }
        subtest 'fixed values are defined...', {
            is $root.getAttribute('fixed'),'foo';
            is $root.getAttributeNS($ns,'ns_fixed'),'ns_foo', 'ns_fixed is ns_foo';
            is $root.getAttribute('a:ns_fixed'),'ns_foo';
            is-deeply $root.hasAttribute('fixed'), False;
            is-deeply $root.hasAttributeNS($ns,'ns_fixed'), False;
            is-deeply $root.hasAttribute('a:ns_fixed'), False;
        }

        subtest 'but no attribute nodes correspond to them', {
            nok defined($root.getAttributeNode('a:ns_fixed'));
            nok defined($root.getAttributeNode('fixed'));
            nok defined($root.getAttributeNode('name'));
            nok defined($root.getAttributeNode('baz'));
            nok defined($root.getAttributeNodeNS($ns,'foo'));
            nok defined($root.getAttributeNodeNS($ns,'fixed'));
            nok defined($root.getAttributeNodeNS($ns,'ns_fixed'));
            nok defined($root.getAttributeNodeNS(Str, 'fixed'));
            nok defined($root.getAttributeNodeNS(Str, 'name'));
            nok defined($root.getAttributeNodeNS(Str, 'baz'));
        }
    }

    {
    my @names = ("nons", "ns");
        for ($xml_nons, $xml_ns) -> $xml {
            my $n = shift(@names);
            my $parser = LibXML.new;
            $parser.complete-attributes = True;
            $parser.expand-entities = True;
            my $doc = $parser.parse: :string($dtd ~ $xml);
            ok($doc, "Could parse document $n");
            my $root = $doc.getDocumentElement;
            subtest "$n getAttributeNode", {
                my $attr = $root.getAttributeNode('foo');
                ok($attr, "Attribute foo exists for $n");
                isa-ok($attr, 'LibXML::Attr',
                    "Attribute is of type LibXML::Attr - $n");
                ok($root.isSameNode($attr.ownerElement),
                    "attr owner element is root - $n");
                is($attr.value, q{"barENT"},
                    "attr value is OK - $n");
                is($attr.serializeContent,
                    '&quot;barENT&quot;',
                    "serializeContent - $n");
                is($attr.gist, 'foo="&quot;barENT&quot;"',
                    "toString - $n");
            }
            subtest "$n fixed values are defined...", {
                is $root.getAttribute('fixed'),'foo';
                is $root.getAttributeNS($ns,'ns_fixed'),'ns_foo';
                is $root.getAttribute('a:ns_fixed'),'ns_foo';
            }
            subtest "and $n attribute nodes are created", {
                my $attr = $root.getAttributeNode('fixed');
                isa-ok $attr, 'LibXML::Attr';
                is $attr.value,'foo';
                is $attr.gist, 'fixed="foo"';
            }
            subtest 'getAttributeNode', {
                my $attr = $root.getAttributeNode('a:ns_fixed');
                isa-ok $attr, 'LibXML::Attr';
                is $attr.value,'ns_foo';
                nok defined($root.getAttributeNode('ns_fixed'));
                nok defined($root.getAttributeNode('name'));
                nok defined($root.getAttributeNode('baz'));
            }
            subtest 'getAttributeNodeNS', {
                my $attr = $root.getAttributeNodeNS($ns,'ns_fixed');
                isa-ok $attr, 'LibXML::Attr';
                is $attr.value,'ns_foo';
                is $attr.gist, 'a:ns_fixed="ns_foo"';
                nok defined($root.getAttributeNodeNS($ns,'foo'));
                nok defined($root.getAttributeNodeNS($ns,'fixed'));
                nok defined($root.getAttributeNodeNS(Str, 'name'));
                nok defined($root.getAttributeNodeNS(Str, 'baz'));
           }

        }
    }
}

subtest 'Entity Reference construction', {
    use LibXML::EntityRef;
    my $doc = LibXML::Document.new();
    my $elem = $doc.createElement( $foo );
    $elem.appendText('a');
    my $ent-ref = LibXML::EntityRef.new(:$doc, :name<bar>);
    is $ent-ref.type, +XML_ENTITY_REF_NODE;
    is $ent-ref.nodeName, 'bar';
    is $ent-ref.ast-key, '&bar';
    is-deeply $ent-ref.xpath-key, Str; # /n/a to xpath
    $elem.appendChild: $ent-ref;
    $elem.appendText('b');
    is $elem.Str, '<foo>a&bar;b</foo>';
}

subtest "issue #41 Traversion order" => {
    plan 6;
    use LibXML::Document;
    my LibXML::Document $doc .= parse: :file<example/dromeds.xml>;
    my @elems = $doc.getElementsByTagName('*');
    is +@elems, 10;
    is @elems[0].tagName, 'dromedaries', 'first element';
    is @elems[1].tagName, 'species', 'second element';
    is @elems[2].tagName, 'humps', 'third element';
    is @elems[3].tagName, 'disposition', 'fourth element';
    is @elems[4].tagName, 'species', 'the fifth element';
}
