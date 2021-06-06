use v6;
use Test;
use LibXML;

plan 44;

my $parser = LibXML.new;

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
    print "$msg\t$$n\n'",(with $n {.Str} else {"NULL"}),"'\n";
}

for (0..1) -> $do-validate {
    my ($n,$doc,$root,$at);
    ok( $doc = $parser.parse(:string($xml1)), ' TODO : Add test name' );
    $root = $doc.getDocumentElement;
    $n = $doc.getElementById('foo');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );

    # old name
    $n = $doc.getElementsById('foo');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );

    $at = $n.getAttributeNode('id');
    ok( $at, ' TODO : Add test name' );
    isa-ok( $at.isId, Bool, 'isId return type');
    ok( $at.isId, ' TODO : Add test name' );

    $at = $root.getAttributeNode('notid');
    ok( $at.isId == 0, ' TODO : Add test name' );

    # _debug("1: foo: ",$n);
    $doc.getDocumentElement.setAttribute('id','bar');
    ok( $doc.validate, ' TODO : Add test name' ) if $do-validate;
    $n = $doc.getElementById('bar');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );

    # _debug("1: bar: ",$n);
    $n = $doc.getElementById('foo');
    ok( !defined($n), ' TODO : Add test name' );
    # _debug("1: !foo: ",$n);

    my $test = $doc.createElement('root');
    $root.appendChild($test);
    $test.setAttribute('id','new');
    ok( $doc.validate, ' TODO : Add test name' ) if $do-validate;
    $n = $doc.getElementById('new');
    ok( $test.isSameNode( $n ), ' TODO : Add test name' );

    $at = $n.getAttributeNode('id');
    ok( $at, ' TODO : Add test name' );
    ok( $at.isId, ' TODO : Add test name' );
    # _debug("1: new: ",$n);
}

{
    my ($n,$doc,$root,$at);
    ok( ($doc = $parser.parse: :string($xml2)), ' TODO : Add test name' );
    $root = $doc.getDocumentElement;

    $n = $doc.getElementById('foo');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );
    # _debug("1: foo: ",$n);

    $doc.getDocumentElement.setAttribute('xml:id','bar');
    $n = $doc.getElementById('foo');
    ok( !defined($n), ' TODO : Add test name' );
    # _debug("1: !foo: ",$n);

    $n = $doc.getElementById('bar');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );

    $at = $n.getAttributeNode('xml:id');
    ok( $at, ' TODO : Add test name' );
    ok( $at.isId, ' TODO : Add test name' );

    $n.setAttribute('id','FOO');
    ok( $at.isSameNode($n.getAttributeNode('xml:id')), ' TODO : Add test name' );

    $at = $n.getAttributeNode('id');
    ok( $at, ' TODO : Add test name' );
    ok( ! $at.isId, ' TODO : Add test name' );

    $at = $n.getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
    ok( $at, ' TODO : Add test name' );
    ok( $at.isId, ' TODO : Add test name' );
    # _debug("1: bar: ",$n);

    $doc.getDocumentElement.setAttributeNS('http://www.w3.org/XML/1998/namespace','id','baz');
    $n = $doc.getElementById('bar');
    ok( !defined($n), ' TODO : Add test name' );
    # _debug("1: !bar: ",$n);

    $n = $doc.getElementById('baz');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );
    # _debug("1: baz: ",$n);
    $at = $n.getAttributeNodeNS('http://www.w3.org/XML/1998/namespace','id');
    ok( $at, ' TODO : Add test name' );
    ok( $at.isId, ' TODO : Add test name' );

    $doc.getDocumentElement.setAttributeNS('http://www.w3.org/XML/1998/namespace','xml:id','bag');
    $n = $doc.getElementById('baz');
    ok( !defined($n), ' TODO : Add test name' );
    # _debug("1: !baz: ",$n);

    $n = $doc.getElementById('bag');
    ok( $root.isSameNode( $n ), ' TODO : Add test name' );
    # _debug("1: bag: ",$n);

    $n.removeAttribute('id');
    is( $root.Str, '<root2 xml:id="bag"/>', ' TODO : Add test name' );
}

