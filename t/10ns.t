use v6;
use Test;
plan 11;

use LibXML;
use LibXML::Enums;
use LibXML::Item;
use LibXML::XPath::Context;
use LibXML::Node::Set;
use LibXML::Attr;
use LibXML::Element;
use LibXML::Namespace;

my LibXML $parser .= new;

my $xml1 = q:to<EOX>;
<a xmlns:b="http://whatever"
><x b:href="out.xml"
/><b:c/></a>
EOX

my $xml2 = q:to<EOX>;
<a xmlns:b="http://whatever" xmlns:c="http://kungfoo"
><x b:href="out.xml"
/><b:c/><c:b/></a>
EOX

my $xml3 = q:to<EOX>;
<a xmlns:b="http://whatever">
    <x b:href="out.xml"/>
    <x>
    <c:b xmlns:c="http://kungfoo">
        <c:d/>
    </c:b>
    </x>
    <x>
    <c:b xmlns:c="http://foobar">
        <c:d/>
    </c:b>
    </x>
</a>
EOX

subtest 'single namespace', {
    my $doc1 = $parser.parse: :string( $xml1 );
    my $elem = $doc1.documentElement;
    is $elem.lookupNamespaceURI( "b" ), "http://whatever";
    my @cn = $elem.childNodes;
    is @cn[0].lookupNamespaceURI( "b" ), "http://whatever";
    is @cn[1].namespaceURI, "http://whatever";
}

subtest 'multiple namespaces', {
    my $doc2 = $parser.parse: :string( $xml2 );

    my $elem = $doc2.documentElement;
    is $elem.lookupNamespaceURI( "b" ), "http://whatever";
    is $elem.lookupNamespaceURI( "c" ), "http://kungfoo";
    my @cn = $elem.childNodes;

    is @cn[0].lookupNamespaceURI( "b" ), "http://whatever";
    is @cn[0].lookupNamespaceURI( "c" ), "http://kungfoo";

    is @cn[1].namespaceURI, "http://whatever";
    is @cn[2].namespaceURI, "http://kungfoo";

    my $namespaces = $elem.findnodes("namespace::*");
    my LibXML::Namespace:D $ns1 = $namespaces[0];
    my $ns2 = $ns1.clone;

    for $ns1, $ns2 -> $ns {
        for :URI<http://kungfoo>, :localname<c>, :name<xmlns:c>, :prefix<xmlns>,  :declaredPrefix<c>, :type(+XML_NAMESPACE_DECL), :Str<xmlns:c="http://kungfoo"> , :unique-key<c|http://kungfoo> {
            is-deeply $ns."{.key}"(), .value, "namespace {.key} accessor";
        }
    }
    is $elem.namespaces.iterator.pull-one.declaredPrefix, 'b', '$elem.namespaces.pull-one';
}

subtest 'nested names', {
    my $doc3 = $parser.parse: :string( $xml3 );
    my $elem = $doc3.documentElement;
    my @cn = $elem.childNodes;
    my @xs = @cn.grep: { .nodeType == XML_ELEMENT_NODE };

    my @x1 = @xs[1].childNodes; my @x2 = @xs[2].childNodes;
    is @x1[1].namespaceURI , "http://kungfoo";
    is @x2[1].namespaceURI , "http://foobar";

    # namespace scoping
    ok !defined($elem.lookupNamespacePrefix( "http://kungfoo" ));
    ok !defined($elem.lookupNamespacePrefix( "http://foobar" ));
}

subtest 'post creation namespace setting', {
    my LibXML::Element $e1 .= new: :name("foo");
    my LibXML::Element $e2 .= new: :name("bar:foo");
    my LibXML::Element $e3 .= new: :name("foo");
    $e3.setAttribute( "kung", "foo" );
    my $a = $e3.getAttributeNode("kung");

    $e1.appendChild($e2);
    $e2.appendChild($e3);
    ok $e2.setNamespace("http://kungfoo", "bar");
    ok $a.setNamespace("http://kungfoo", "bar");
    is $a.nodeName, "bar:kung";
}

subtest 'importing namespaces', {

    my $doca = LibXML.createDocument;
    my $docb = LibXML.parse: :string( q:to<EOX>);
    <x:a xmlns:x="http://foo.bar"><x:b/></x:a>
    EOX

    my $b = $docb.documentElement.firstChild;

    my $c = $doca.importNode( $b );
    my LibXML::Item @attra = $c.properties.Slip, $c.namespaces.Slip;
    is +@attra, 1;
    is @attra[0].nodeType, 18;

    my $d = $doca.adoptNode($b);
    ok $d.isSameNode( $b );
    my LibXML::Item @attrb = $d.properties.Slip, $c.namespaces.Slip;
    is +@attrb, 1;
    is @attrb[0].nodeType, 18;
}

subtest 'lossless setting of namespaces with setAttribute',  {
    # Perl report by Kurt George Gjerde
    my $doc = LibXML.createDocument;
    my $root = $doc.createElementNS('http://example.com', 'document');
    $root.setAttribute('xmlns:xxx', 'http://example.com');
    $root.setAttribute('xmlns:yyy', 'http://yonder.com');
    $doc.setDocumentElement( $root );

    my $strnode = $root.Str();
    ok ($strnode ~~ /'xmlns:xxx'/ and $strnode ~~ /'xmlns='/);
}

subtest 'namespaced attributes', {
    my $doc = LibXML.parse: :string(q:to<EOF>);
    <test xmlns:xxx="http://example.com"/>
    EOF
    my $root = $doc.getDocumentElement();
    # namespaced attributes
    $root.setAttribute('xxx:attr', 'value');
    ok $root.getAttributeNode('xxx:attr');
    is $root.getAttribute('xxx:attr'), 'value';
    ok $root.getAttributeNodeNS('http://example.com','attr');
    is $root.getAttributeNS('http://example.com','attr'), 'value';
    is $root.getAttributeNode('xxx:attr').getNamespaceURI(), 'http://example.com';

    #change encoding to UTF-8 and retest
    $doc.encoding = 'UTF-8';
    # namespaced attributes
    $root.setAttribute('xxx:attr', 'value');
    ok $root.getAttributeNode('xxx:attr');
    is $root.getAttribute('xxx:attr'), 'value';
    ok $root.getAttributeNodeNS('http://example.com','attr');
    is $root.getAttributeNS('http://example.com','attr'), 'value';
    is $root.getAttributeNode('xxx:attr').getNamespaceURI(), 'http://example.com';
}


subtest 'Namespace Declarations', {
    my $xmlns = 'http://www.w3.org/2000/xmlns/';

    my $doc = LibXML.createDocument;
    my $root = $doc.createElementNS('http://example.com', 'document');
    $root.setAttributeNS($xmlns, 'xmlns:xxx', 'http://example.com');
    $root.setAttribute('xmlns:yyy', 'http://yonder.com');
    $doc.setDocumentElement( $root );

    subtest 'get namespace', {
        is  $root.getAttribute('xmlns:xxx'), 'http://example.com';
        is $root.getAttributeNS($xmlns,'xmlns'), 'http://example.com';
        is  $root.getAttribute('xmlns:yyy'), 'http://yonder.com';
        is  $root.lookupNamespacePrefix('http://yonder.com'), 'yyy';
        is  $root.lookupNamespaceURI('yyy'), 'http://yonder.com';
    }

    subtest 'changing namespace', {
        ok $root.setAttribute('xmlns:yyy', 'http://newyonder.com');
        is  $root.getAttribute('xmlns:yyy'), 'http://newyonder.com';
        is  $root.lookupNamespacePrefix('http://newyonder.com'), 'yyy';
        is  $root.lookupNamespaceURI('yyy'), 'http://newyonder.com';
    }

    subtest 'changing default namespace', {
        $root.setAttribute('xmlns', 'http://other.com' );
        is $root.getAttribute('xmlns'), 'http://other.com';
        is $root.lookupNamespacePrefix('http://other.com'), "";
        is $root.lookupNamespaceURI(''), 'http://other.com';
    }

    subtest 'non-existent namespaces', {
        is-deeply $root.lookupNamespaceURI('foo'), Str;
        is-deeply $root.lookupNamespacePrefix('foo'), Str;
        is-deeply $root.getAttribute('xmlns:foo'), Str;
    }

    subtest 'changing namespace declaration URI and prefix', {
        ok $root.setNamespaceDeclURI('yyy', 'http://changed.com');
        is  $root.getAttribute('xmlns:yyy'), 'http://changed.com';
        is  $root.lookupNamespaceURI('yyy'), 'http://changed.com';
        dies-ok { $root.setNamespaceDeclPrefix('yyy','xxx'); }, 'prefix occupied';
        dies-ok { $root.setNamespaceDeclPrefix('yyy',''); };
        ok $root.setNamespaceDeclPrefix('yyy', 'zzz');
        is-deeply $root.lookupNamespaceURI('yyy'), Str;
        is $root.lookupNamespaceURI('zzz'), 'http://changed.com';
        ok $root.setNamespaceDeclURI('zzz', Str );
        is $root.lookupNamespaceURI('zzz'), Str;

        my $strnode = $root.Str();
        ok $strnode !~~ /'xmlns:zzz'/;
    }

    subtest 'changing the default namespace declaration', {
        ok $root.setNamespaceDeclURI('','http://test');
        is $root.lookupNamespaceURI(''), 'http://test';
        is $root.getNamespaceURI(), 'http://test';
    }

    subtest 'changing prefix of the default ns declaration', {
        ok $root.setNamespaceDeclPrefix('','foo');
        is-deeply $root.lookupNamespaceURI(''), Str;
        is $root.lookupNamespaceURI('foo'), 'http://test';
        is $root.getNamespaceURI(),  'http://test';
        is $root.prefix(),  'foo';
    }

    subtest 'turning a ns declaration to a default ns declaration', {
        ok $root.setNamespaceDeclPrefix('foo','');
        is-deeply $root.lookupNamespaceURI('foo'), Str;
        is $root.lookupNamespaceURI(''), 'http://test';
        is $root.lookupNamespaceURI(Str), 'http://test';
        is $root.getNamespaceURI(),  'http://test';
        is-deeply $root.prefix(), Str;
    }

    subtest 'removing the default ns declaration', {
        ok $root.setNamespaceDeclURI('',Str);
        is-deeply $root.lookupNamespaceURI(''), Str;
        is-deeply $root.getNamespaceURI(), Str;

        my $strnode = $root.Str();
        ok $strnode !~~ /'xmlns='/;
    }

    subtest 'namespaced attributes', {
        $root.setAttribute('xxx:attr', 'value');
        ok $root.getAttributeNode('xxx:attr');
        is $root.getAttribute('xxx:attr'), 'value';
        ok $root.getAttributeNodeNS('http://example.com','attr');
        is $root.getAttributeNS('http://example.com','attr'), 'value';
        is $root.getAttributeNode('xxx:attr').getNamespaceURI(), 'http://example.com';
    }

    subtest 'removing other xmlns declarations', {
        $root.addNewChild('http://example.com', 'xxx:foo');
        ok $root.setNamespaceDeclURI('xxx',Str);
        is-deeply $root.lookupNamespaceURI('xxx'), Str;
        is-deeply $root.getNamespaceURI(), Str;
        is-deeply $root.firstChild.getNamespaceURI(), Str;
        is-deeply $root.prefix(), Str;
        is-deeply $root.firstChild.prefix(), Str;
    }

    subtest 'check namespaced attributes', {
        is-deeply $root.getAttributeNode('xxx:attr'), LibXML::Attr;
        is-deeply $root.getAttributeNodeNS('http://example.com', 'attr'), LibXML::Attr;
        ok $root.getAttributeNode('attr');
        is $root.getAttribute('attr'), 'value';
        ok $root.getAttributeNodeNS(Str,'attr');
        is $root.getAttributeNS(Str,'attr'), 'value';
        is-deeply $root.getAttributeNode('attr').getNamespaceURI(), Str;

        my $strnode = $root.Str();
        ok $strnode !~~ /'xmlns='/;
        ok $strnode !~~ /'xmlns:xxx='/;
        ok $strnode ~~ /'<foo'/,;

        ok $root.setNamespaceDeclPrefix('xxx', Str);

        is $doc.findnodes('/document/foo').size(), 1;
        is $doc.findnodes('/document[foo]').size(), 1;
        is $doc.findnodes('/document[*]').size(), 1;
        is $doc.findnodes('/document[@attr and foo]').size(), 1;
        is $doc.findvalue('/document/@attr'), 'value';

        my LibXML::XPath::Context $xp .= new: :$doc;
        is $xp.findnodes('/document/foo').size(), 1;
        is $xp.findnodes('/document[foo]').size(), 1;
        is $xp.findnodes('/document[*]').size(), 1;

        is $xp.findnodes('/document[@attr and foo]').size(), 1;
        is $xp.findvalue('/document/@attr'), 'value';

        is-deeply $root.firstChild.prefix(), Str;
    }
}

subtest 'namespace reconciliation', {
    my $doc = LibXML.createDocument( 'http://default', 'root' );
    my $root = $doc.documentElement;
    $root.addNamespace( 'http://children', 'child');

    $root.appendChild( my $n = $doc.createElementNS( 'http://default', 'branch' ));
    # appending an element in the same namespace will
    # strip its declaration
    ok !defined($n.getAttribute( 'xmlns' ));

    $n.appendChild( my $a = $doc.createElementNS( 'http://children', 'child:a' ));
    $n.appendChild( my $b = $doc.createElementNS( 'http://children', 'child:b' ));

    $n.appendChild( my $c = $doc.createElementNS( 'http://children', 'child:c' ));
    # appending $c strips the declaration
    ok !defined($c.getAttribute('xmlns:child'));

    # add another prefix for children
    $c.setAttribute( 'xmlns:foo', 'http://children' );
    is $c.getAttribute( 'xmlns:foo' ), 'http://children';

    $n.appendChild( my $d = $doc.createElementNS( 'http://other', 'branch' ));
    # appending an element with a new default namespace
    # will leave it declared
    is $d.getAttribute( 'xmlns' ), 'http://other';

    my $doca = LibXML.createDocument( 'http://default/', 'root' );
    $doca.adoptNode( $a );
    $doca.adoptNode( $b );
    $doca.documentElement.appendChild( $a );
    $doca.documentElement.appendChild( $b );

    # Because the child namespace isn't defined in $doca
    # it should get declared on both child nodes $a and $b
    is $a.getAttribute( 'xmlns:child' ), 'http://children';
    is $b.getAttribute( 'xmlns:child' ), 'http://children';

    $doca = LibXML.createDocument( 'http://children', 'child:root' );
    $doca.adoptNode( $a );
    $doca.documentElement.appendChild( $a );

    # $doca declares the child namespace, so the declaration
    # should now get stripped from $a
    ok !defined($a.getAttribute( 'xmlns:child' ));

    $doca.documentElement.removeChild( $a );

    # $a should now have its namespace re-declared
    is $a.getAttribute( 'xmlns:child' ), 'http://children';

    $doca.documentElement.appendChild( $a );

    # $doca declares the child namespace, so the declaration
    # should now get stripped from $a
    ok !defined($a.getAttribute( 'xmlns:child' ));

    $doc = LibXML::Document.new;
    $n = $doc.createElement( 'didl' );
    $n.setAttribute( "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance" );

    $a = $doc.createElement( 'dc' );
    $a.setAttribute( "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance" );
    $a.setAttribute( "xsi:schemaLocation"=>"http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives
.org/OAI/2.0/oai_dc.xsd" );

    $n.appendChild( $a );

    # the declaration for xsi should be stripped
    ok !defined($a.getAttribute( 'xmlns:xsi' ));

    $n.removeChild( $a );

    # should be a new declaration for xsi in $a
    is $a.getAttribute( 'xmlns:xsi' ), 'http://www.w3.org/2001/XMLSchema-instance';

    $b = $doc.createElement( 'foo' );
    $b.setAttribute( 'xsi:bar', 'bar' );
    $n.appendChild( $b );
    $n.removeChild( $b );

    # a prefix without a namespace can't be reliably compared,
    # so $b doesn't acquire a declaration from $n!
    ok !defined($b.getAttribute( 'xmlns:xsi' ));

    # tests for reconciliation during setAttributeNodeNS
    my $attr = $doca.createAttributeNS(
        'http://children', 'child:attr', 'value'
    );
    ok $attr.defined;
    my $child = $doca.documentElement.firstChild;
    ok $child.defined;
    $child.setAttributeNodeNS($attr);
    ok !defined($child.getAttribute( 'xmlns:child' ));

    # due to libxml2 limitation, LibXML declares the namespace
    # on the root element
    $attr = $doca.createAttributeNS('http://other','other:attr','value');
    ok $attr.defined;
    $child.setAttributeNodeNS($attr);
    #
    ok !defined($child.getAttribute( 'xmlns:other' ));
    ok defined($doca.documentElement.getAttribute( 'xmlns:other' ));
}

subtest 'xml namespace', {
    my $docOne = LibXML.parse: :string(
        '<foo><inc xml:id="test"/></foo>'
    );
    my $docTwo = LibXML.parse: :string(
        '<bar><urgh xml:id="foo"/></bar>'
    );

    my $inc = $docOne.getElementById('test');
    my $rep = $docTwo.getElementById('foo');
    $inc.parentNode.replaceChild($rep, $inc);
    is $inc.getAttributeNS('http://www.w3.org/XML/1998/namespace','id'), 'test';
    ok $inc.isSameNode($docOne.getElementById('test'));
}

subtest 'empty namespace', {
    my $doc = LibXML.load: string => $xml1;
    my LibXML::Element $node = $doc.first('/a/b:c');

    ok($node.setNamespace(""), 'removing ns from elemenet');
    is-deeply($node.prefix, Str, 'ns prefix removed from element');
    is-deeply($node.namespaceURI, Str, 'ns removed from element');
    is($node.getName, 'c', 'ns removed from element name');

    my LibXML::Attr $attr = $doc.first('/a/x/@b:href');

    ok($attr.setNamespace("", ""), 'removing ns from attr');
    is-deeply($attr.prefix, Str, 'ns prefix removed from attr');
    is-deeply($attr.namespaceURI, Str, 'ns removed from attr');
    is($attr.getName, 'href', 'ns removed from attr name');
}
