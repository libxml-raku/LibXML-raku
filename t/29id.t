use v6;
use Test;
use LibXML;

plan 3;

my LibXML $parser .= new;

my $xml1 = q:to<EOF>;
<!DOCTYPE root [
<!ELEMENT root (root?)>
<!ATTLIST root id ID #REQUIRED
               notid CDATA #IMPLIED
>
]>
<root id="foo" notid="x"/>
EOF

my $xml2 = q:to<EOF>;
<root2 xml:id="foo"/>
EOF

sub _debug($msg,$n) {
    say "## $msg\t$$n\n'",(.Str // "NULL"),"'";
}

for (0..1) -> $do-validate {
    subtest 'basic' ~ ($do-validate ?? ' (validation)' !! ''), {
        my ($n,$doc,$root,$at);
        ok $doc = $parser.parse(:string($xml1)), 'parse';
        $root = $doc.getDocumentElement;
        $n = $doc.getElementById('foo');
        ok $root.isSameNode( $n ), 'getElementById on root node';

        # old name
        $n = $doc.getElementsById('foo');
        ok $root.isSameNode( $n ), 'getElementsById on root node';

        $at = $n.getAttributeNode('id');
        ok $at.defined, 'getAttributeNode';
        isa-ok $at.isId, Bool, 'isId return type';
        ok $at.isId, 'isId return value';

        $at = $root.getAttributeNode('notid');
        nok $at.isId, 'getAttributeNode on non-Id';

        # _debug("1: foo: ",$n);
        $doc.getDocumentElement.setAttribute('id','bar');
        ok( $doc.validate, 'validate' ) if $do-validate;
        $n = $doc.getElementById('bar');
        ok $root.isSameNode( $n ), 'getElementByID on new attribute node';

        # _debug("1: bar: ",$n);
        $n = $doc.getElementById('foo');
        ok( !defined($n) );
        # _debug("1: !foo: ",$n);

        my $test = $doc.createElement('root');
        $root.appendChild($test);
        $test.setAttribute('id','new');
        ok( $doc.validate, 'validate' ) if $do-validate;
        $n = $doc.getElementById('new');
        ok( $test.isSameNode( $n ), 'getElementByID on new child/attribute' );

        $at = $n.getAttributeNode('id');
        ok $at.defined;
        ok $at.isId;
        # _debug("1: new: ",$n);
    }
}

subtest 'namespaces', {
    my ($n,$doc,$root,$at);
    ok $doc = $parser.parse(:string($xml2)), 'parse';
    $root = $doc.getDocumentElement;

    $n = $doc.getElementById('foo');
    ok $root.isSameNode( $n ), 'getElementById on root node';
    # _debug("1: foo: ",$n);

    $doc.getDocumentElement.setAttribute('xml:id','bar');
    $n = $doc.getElementById('foo');
    nok defined($n), 'getElementByID on old id';
    # _debug("1: !foo: ",$n);

    $n = $doc.getElementById('bar');
    ok $root.isSameNode( $n ), 'getElementByID on new id';

    $at = $n.getAttributeNode('xml:id');
    ok $at, 'getAttributeNode on xml:id';
    ok $at.isId, 'isId()';

    $n.setAttribute('id','FOO');
    ok $at.isSameNode($n.getAttributeNode('xml:id')), 'getAttributeNode on xml:id';

    $at = $n.getAttributeNode('id');
    ok $at.defined, 'getAttributeNode';
    nok $at.isId, 'id occluded by xml:id';

    $at = $n.getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
    ok $at.defined, 'getAttributeNodeNS';
    ok $at.isId, 'isId()';
    # _debug("1: bar: ",$n);

    $doc.getDocumentElement.setAttributeNS('http://www.w3.org/XML/1998/namespace','id','baz');
    $n = $doc.getElementById('bar');
    nok defined($n);
    # _debug("1: !bar: ",$n);

    $n = $doc.getElementById('baz');
    ok $root.isSameNode( $n ), 'getAttributeNS';
    # _debug("1: baz: ",$n);
    $at = $n.getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
    ok $at.defined;
    ok $at.isId, 'getAttributeNodeNS';

    $doc.getDocumentElement.setAttributeNS('http://www.w3.org/XML/1998/namespace','xml:id','bag');
    $n = $doc.getElementById('baz');
    nok defined($n);
    # _debug("1: !baz: ",$n);

    $n = $doc.getElementById('bag');
    ok $root.isSameNode( $n ), 'id updated via setAttributeNS';
    # _debug("1: bag: ",$n);

    $n.removeAttribute('id');
    is $root.Str, '<root2 xml:id="bag"/>', 'xml';
}

