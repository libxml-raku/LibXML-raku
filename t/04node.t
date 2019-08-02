# -*- perl6 -*-

##
# this test checks the DOM Node interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

# since all tests are run on a preparsed

use v6;
use Test;
plan 177;

use LibXML;
use LibXML::Enums;

my $xmlstring = q{<foo>bar<foobar/><bar foo="foobar"/><!--foo--><![CDATA[&foo bar]]></foo>};

my LibXML $parser .= new;
my $doc    = $parser.parse: :string( $xmlstring );

# 1   Standalone Without NameSpaces
# 1.1 Node Attributes

{
    my $node = $doc.documentElement;
    my $rnode;

    # TEST

    is($node, $xmlstring, ' TODO : Add test name');
    # TEST
    is($node.nodeType, +XML_ELEMENT_NODE, ' TODO : Add test name');
    # TEST
    is($node.nodeName, "foo", ' TODO : Add test name');
    # TEST
    ok(!defined( $node.nodeValue ), ' TODO : Add test name');
    # TEST
    ok($node.hasChildNodes, ' TODO : Add test name');
    # TEST
    is($node.textContent, "bar&foo bar", ' TODO : Add test name');

    {
        my @children = $node.childNodes;
        # TEST
        is( +@children, 5, ' TODO : Add test name' );
        # TEST
        is( @children[0].nodeType, +XML_TEXT_NODE, ' TODO : Add test name' );
        # TEST
        is( @children[0].nodeValue, "bar", ' TODO : Add test name' );
        # TEST
        is( @children[4].nodeType, +XML_CDATA_SECTION_NODE, ' TODO : Add test name' );
        # TEST
        is( @children[4].nodeValue, "&foo bar", ' TODO : Add test name' );

        my $fc = $node.firstChild;
        # TEST
        ok( $fc, ' TODO : Add test name' );
        # TEST
        ok( $fc.isSameNode(@children[0]), ' TODO : Add test name');
        # TEST
        ok( !defined($fc.baseURI), ' TODO : Add test name' );

        my $od = $fc.ownerDocument;
        # TEST
        ok( $od, ' TODO : Add test name' );
        # TEST
        ok( $od.isSameNode($doc), ' TODO : Add test name');

        my $xc = $fc.nextSibling;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc.isSameNode(@children[1]), ' TODO : Add test name' );

        $fc = $node.lastChild;
        # TEST
        ok( $fc, ' TODO : Add test name' );
        # TEST
        ok( $fc.isSameNode(@children[4]), ' TODO : Add test name');

        $xc = $fc.previousSibling;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc.isSameNode(@children[3]), ' TODO : Add test name' );
        $rnode = $xc;

        $xc = $fc.parentNode;
        # TEST
        ok( $xc, ' TODO : Add test name' );
        # TEST
        ok( $xc.isSameNode($node), ' TODO : Add test name' );

        $xc = @children[2];
        {
            # 1.2 Attribute Node
            # TEST
            ok( $xc.hasAttributes, 'hasAttributes' );
            my $attributes = $xc.attributes;
            # TEST
            ok( $attributes, 'got attributes' );
            # TEST

            isa-ok( $attributes, "LibXML::Attr::Map", ' TODO : Add test name' );
            # TEST
            is( +$attributes, 1, ' TODO : Add test name' );
            my $attr = $attributes<foo>;

            # TEST

            is( $attr, 'foobar', ' TODO : Add test name' );
            # TEST
            is( $attr.nodeType, +XML_ATTRIBUTE_NODE, ' TODO : Add test name' );
            # TEST
            is( $attr.nodeName, "foo", ' TODO : Add test name' );
            # TEST
            is( $attr.nodeValue, "foobar", ' TODO : Add test name' );
            # TEST
            is-deeply( $attr.hasChildNodes, False, ' TODO : Add test name');
        }

        {
            my %attributes := $xc.attributes;
            # TEST
            is( + %attributes, 1, ' TODO : Add test name' );
        }

        # 1.2 Node Cloning
        {
            my $cnode  = $doc.createElement("foo");
	    $cnode.setAttribute('aaa','AAA');
	    $cnode.setAttributeNS('http://ns','x:bbb','BBB');
            my $c1node = $doc.createElement("bar");
            $cnode.appendChild( $c1node );
            is( $cnode, '<foo xmlns:x="http://ns" aaa="AAA" x:bbb="BBB"><bar/></foo>', ' TODO : Add test name' );

            my $xnode = $cnode.cloneNode();
            # TEST
            is( $xnode, '<foo xmlns:x="http://ns" aaa="AAA" x:bbb="BBB"/>', ' TODO : Add test name' );
            # TEST
            is( $xnode.nodeName, "foo", ' TODO : Add test name' );
            # TEST
            ok( ! $xnode.hasChildNodes, ' TODO : Add test name' );
	    # TEST
	    is( $xnode.getAttribute('aaa'),'AAA', ' TODO : Add test name' );
	    # TEST

	    is( $xnode.getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            $xnode = $cnode.cloneNode(:deep);
            # TEST
            ok( $xnode, ' TODO : Add test name' );
            # TEST
            is( $xnode.nodeName, "foo", ' TODO : Add test name' );
            # TEST
            ok( $xnode.hasChildNodes, ' TODO : Add test name' );
	    # TEST
	    is( $xnode.getAttribute('aaa'),'AAA', ' TODO : Add test name' );
	    # TEST
	    is( $xnode.getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            my @cn = $xnode.childNodes;
            # TEST
            ok( @cn, ' TODO : Add test name' );
            # TEST
            is( +@cn, 1, ' TODO : Add test name');
            # TEST
            is( @cn[0].nodeName, "bar", ' TODO : Add test name' );
            # TEST
            ok( !@cn[0].isSameNode( $c1node ), ' TODO : Add test name' );

            # clone namespaced elements
            my $nsnode = $doc.createElementNS( "fooNS", "foo:bar" );

            my $cnsnode = $nsnode.cloneNode();
            # TEST
            is( $cnsnode.nodeName, "foo:bar", ' TODO : Add test name' );
            # TEST
            ok( $cnsnode.localNS(), ' TODO : Add test name' );
            # TEST
            is( $cnsnode.namespaceURI(), 'fooNS', ' TODO : Add test name' );

            # clone namespaced elements (recursive)
            my $c2nsnode = $nsnode.cloneNode(:deep);
            # TEST
            is( $c2nsnode.Str, $nsnode.Str, ' TODO : Add test name' );
        }

        # 1.3 Node Value
        my $string2 = "<foo>bar<tag>foo</tag></foo>";
        {
            my $doc2 = $parser.parse: :string( $string2 );
            my $root = $doc2.documentElement;
            # TEST
            ok( ! defined($root.nodeValue), ' TODO : Add test name' );
            # TEST
            is( $root.textContent, "barfoo", ' TODO : Add test name');
        }
    }

    {
        my $children = $node.childNodes;
        # TEST
        ok( defined($children), ' TODO : Add test name' );
        # TEST
        isa-ok( $children, "LibXML::Node::List", ' TODO : Add test name' );
    }


    # 2. (Child) Node Manipulation

    # 2.1 Valid Operations

    {
        # 2.1.1 Single Node

        my $inode = $doc.createElement("kungfoo"); # already tested
        my $jnode = $doc.createElement("kungfoo");
        my $xn = $node.insertBefore($inode, $rnode);
        # TEST
        ok( $xn, ' TODO : Add test name' );
        # TEST
        ok( $xn.isSameNode($inode), ' TODO : Add test name' );

        $node.insertBefore( $jnode, LibXML::Node );
        my $children := $node.childNodes();
        my $n = 0; $n++ for $children;
        is $n, 7, 'iterator';
        $n = 0; $n++ for $children;
        is $n, 7, 'iterator';

        my @ta  = $node.childNodes();
        $xn = pop @ta;
        # TEST
        ok( $xn.isSameNode( $jnode ), ' TODO : Add test name' );

        $jnode.unbindNode;
        $node.Str;

        my @cn = $node.childNodes;
        # TEST
        is(+@cn, 6, ' TODO : Add test name');
        # TEST
        ok( @cn[3].isSameNode($inode), ' TODO : Add test name' );

        $xn = $node.removeChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode($inode), ' TODO : Add test name');

        @cn = $node.childNodes;
        # TEST
        is(+@cn, 5, ' TODO : Add test name');
        # TEST
        ok( @cn[3].isSameNode($rnode), ' TODO : Add test name' );

        $xn = $node.appendChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode($inode), ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode($node.lastChild), ' TODO : Add test name');

        $xn = $node.removeChild($inode);
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode($inode), ' TODO : Add test name');
        # TEST
        ok(@cn.tail.isSameNode($node.lastChild), ' TODO : Add test name');

        $xn = $node.replaceChild( $inode, $rnode );
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode($rnode), ' TODO : Add test name');

        my @cn2 = $node.childNodes;
        # TEST
        is(+@cn, 5, ' TODO : Add test name');
        # TEST
        ok( @cn2[3].isSameNode($inode), ' TODO : Add test name' );
    }

    {
        # insertAfter Tests
        my $anode = $doc.createElement("a");
        my $bnode = $doc.createElement("b");
        my $cnode = $doc.createElement("c");
        my $dnode = $doc.createElement("d");

        $anode.insertAfter( $bnode, LibXML::Node );
        # TEST
        is( $anode.Str(), '<a><b/></a>', ' TODO : Add test name' );

        $anode.insertAfter( $dnode, LibXML::Node );
        # TEST
        is( $anode.Str(), '<a><b/><d/></a>', ' TODO : Add test name' );

        $anode.insertAfter( $cnode, $bnode );
        # TEST
        is( $anode.Str(), '<a><b/><c/><d/></a>', ' TODO : Add test name' );

    }

    {
        my ($inode, $jnode );

        $inode = $doc.createElement("kungfoo"); # already tested
        $jnode = $doc.createElement("foobar");

        my $xn = $inode.insertBefore( $jnode, LibXML::Node);
        # TEST
        ok( $xn, ' TODO : Add test name' );
        # TEST
        ok( $xn.isSameNode( $jnode ), ' TODO : Add test name' );
    }

    {
        # 2.1.2 Document Fragment
        my @cn   = $doc.documentElement.childNodes;
        my $rnode= $doc.documentElement;

        my $frag = $doc.createDocumentFragment;
        is $frag.nodeType, +XML_DOCUMENT_FRAG_NODE, 'nodeType';

        my $node1 = $doc.createElement("kung");
        my $node2 = $doc.createElement("foobar1");

        $frag.appendChild($node1);
        $frag.appendChild($node2);
        is $frag, '<kung/><foobar1/>', 'frag';

        my $xn = $node.appendChild( $frag );

        # TEST
        ok($xn, ' TODO : Add test name');
        my @cn2 = $node.childNodes;
         # TEST
        is(+@cn2, 7, ' TODO : Add test name');
        # TEST
        ok(@cn2[*-1].isSameNode($node2), ' TODO : Add test name');
        # TEST
        ok(@cn2[*-2].isSameNode($node1), ' TODO : Add test name');

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );
        @cn2 = $node.childNodes;
        # TEST
        is(+@cn2, 5, ' TODO : Add test name');

        $xn = $node.replaceChild( $frag, @cn[3] );

       # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($xn.isSameNode(@cn[3]), ' TODO : Add test name');
        @cn2 = $node.childNodes;
        # TEST
        is(+@cn2, 6, ' TODO : Add test name');

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );

        $xn = $node.insertBefore( $frag, @cn[0] );
        # TEST
        ok($xn, ' TODO : Add test name');
        # TEST
        ok($node1.isSameNode($node.firstChild), ' TODO : Add test name');
        @cn2 = $node.childNodes;
        # TEST
        is(+@cn2, 6, ' TODO : Add test name');
    }

    # 2.2 Invalid Operations


    # 2.3 DOM extensions
    {
        my $string = "<foo><bar/>com</foo>";
        my $doc = LibXML.new.parse: :$string;
        my $elem= $doc.documentElement;
        # TEST
        is( $elem, '<foo><bar/>com</foo>', ' TODO : Add test name' );
        # TEST
        ok( $elem.hasChildNodes, 'hasChildNodes' );
        my $frag = $elem.removeChildNodes;
        isa-ok $frag, 'LibXML::DocumentFragment', 'removed child nodes';
        is $frag, '<bar/>com', 'removed child nodes';
        # TEST
        nok( $elem.hasChildNodes, 'hasChildNodes after removal' );
        $elem.Str;
    }
}

# 3   Standalone With NameSpaces

{
    my $doc = LibXML::Document.new();
    my $URI ="http://kungfoo";
    my $pre = "foo";
    my $name= "bar";

    my $elem = $doc.createElementNS($URI, $pre~":"~$name);

    # TEST

    ok($elem, ' TODO : Add test name');
    # TEST
    is($elem.nodeName, $pre~":"~$name, ' TODO : Add test name');
    # TEST
    is($elem.namespaceURI, $URI, ' TODO : Add test name');
    # TEST
    is($elem.prefix, $pre, ' TODO : Add test name');
    # TEST
    is($elem.localname, $name, ' TODO : Add test name' );

    # TEST

    is( $elem.lookupNamespacePrefix( $URI ), $pre, ' TODO : Add test name');
    # TEST
    is( $elem.lookupNamespaceURI( $pre ), $URI, ' TODO : Add test name');

    my @ns = $elem.getNamespaces;
    # TEST
    is( +@ns, 1, ' TODO : Add test name' );
}

# 4.   Document switching

{
    # 4.1 simple document
    my $docA = LibXML::Document.new;
    {
        my $docB = LibXML::Document.new;
        my $e1   = $docB.createElement( "A" );
        my $e2   = $docB.createElement( "B" );
        my $e3   = $docB.createElementNS( "http://kungfoo", "C:D" );
        $e1.appendChild( $e2 );
        $e1.appendChild( $e3 );

        $docA.setDocumentElement( $e1 );
    }
    my $elem = $docA.documentElement;
    my @c = $elem.childNodes;
    my $xroot = @c[0].ownerDocument;
    # TEST
    ok( $xroot.isSameNode($docA), ' TODO : Add test name' );

}

# 5.   libxml2 specials

{
    my $docA = LibXML::Document.new;
    my $e1   = $docA.createElement( "A" );
    my $e2   = $docA.createElement( "B" );
    my $e3   = $docA.createElement( "C" );

    $e1.appendChild( $e2 );
    my $x = $e2.replaceNode( $e3 );
    my @cn = $e1.childNodes;
    # TEST
    ok(@cn, ' TODO : Add test name');
    # TEST
    is( +@cn, 1, ' TODO : Add test name' );
    # TEST
    ok(@cn[0].isSameNode($e3), ' TODO : Add test name');
    # TEST
    ok($x.isSameNode($e2), ' TODO : Add test name');

    $e3.addSibling( $e2 );
    @cn = $e1.childNodes;
    # TEST
    is( +@cn, 2, ' TODO : Add test name' );
    # TEST
    ok(@cn[0].isSameNode($e3), ' TODO : Add test name');
    # TEST
    ok(@cn[1].isSameNode($e2), ' TODO : Add test name');
}

# 6.   implicit attribute manipulation

{
    my $parser = LibXML.new();
    my $doc = $parser.parse: :string( '<foo bar="foo"/>' );
    my $root = $doc.documentElement;
    my $attributes := $root.attributes;
    is( +$attributes, 1, ' TODO : Add test name');
    # TEST
    ok($attributes, ' TODO : Add test name');
    my $newAttr = $doc.createAttribute( "kung", "foo" );
    $attributes.setNamedItem( $newAttr );

    my %att := $root.attributes;
    # TEST
    ok(%att, ' TODO : Add test name');
    # TEST
    is( +%att, 2, ' TODO : Add test name');
    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "foo" );

    $attributes.setNamedItem($newAttr);
    %att := $root.attributes;
    # TEST
    ok(%att, ' TODO : Add test name');
    # TEST
    is( +%att.keys, 2, ' TODO : Add test name');
    is( +%att<http://kungfoo>, 1, ' TODO : Add test name');

    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "bar" );
    $attributes.setNamedItem($newAttr);
    %att := $root.attributes;
    # TEST
    ok(%att, ' TODO : Add test name');
    # TEST
    is( +%att, 2, ' TODO : Add test name');
    # TEST
    is(%att<http://kungfoo><kung>, $newAttr.nodeValue, ' TODO : Add test name');

    $attributes.removeNamedItemNS( "http://kungfoo", "kung");
    %att := $root.attributes;
    # TEST
    is( +%att, 1, ' TODO : Add test name');
    # TEST
    is($attributes.elems, 1, ' TODO : Add test name');
}

# 7. importing and adopting

{
    my $parser = LibXML.new;
    my $doc1 = $parser.parse: :string( "<foo>bar<foobar/></foo>" );
    my $doc2 = LibXML::Document.new;

    # TEST

    ok( $doc1 && $doc2, ' TODO : Add test name' );
    my $rnode1 = $doc1.documentElement;
    # TEST
    ok( $rnode1, ' TODO : Add test name' );
    my $rnode2 = $doc2.importNode( $rnode1 );
    # TEST
    ok( ! $rnode2.isSameNode( $rnode1 ), ' TODO : Add test name' ) ;
    $doc2.setDocumentElement( $rnode2 );
    my $node = $rnode2.cloneNode();
    # TEST
    ok( $node, ' TODO : Add test name' );
    my $cndoc = $node.ownerDocument;
    # TEST
    ok( $cndoc.defined, ' TODO : Add test name' );
    # TEST
    ok( $cndoc.isSameNode( $doc2 ), ' TODO : Add test name' );

    my $xnode = LibXML::Element.new: :name<test>;

    my $node2 = $doc2.importNode($xnode);
    # TEST
    ok( $node2, ' TODO : Add test name' );
    my $cndoc2 = $node2.ownerDocument;
    # TEST
    ok( $cndoc2, ' TODO : Add test name' );
    # TEST
    ok( $cndoc2.isSameNode( $doc2 ), ' TODO : Add test name' );

    my $doc3 = LibXML::Document.new;
    my $node3 = $doc3.adoptNode( $xnode );
    # TEST
    ok( $node3, ' TODO : Add test name' );
    # TEST
    ok( $xnode.isSameNode( $node3 ), ' TODO : Add test name' );
    # TEST
    ok $node3.ownerDocument.defined, "have owner document";
    ok( $doc3.isSameNode( $node3.ownerDocument ), ' TODO : Add test name' );

    my $xnode2 = LibXML::Element.new: :name<test>;
    $xnode2.setOwnerDocument( $doc3 ); # alternate version of adopt node
    # TEST
    ok( $xnode2.ownerDocument, 'setOwnerDocument' );
    # TEST
    ok( $doc3.isSameNode( $xnode2.ownerDocument ), 'setOwnerDocument' );
}

{
  # appending empty fragment
  my $doc = LibXML::Document.new();
  my $frag = $doc.createDocumentFragment();
  my $root = $doc.createElement( 'foo' );
  my $r = $root.appendChild( $frag );
  # TEST
  nok( $r, 'append empty fragment' );
}

{
   my $doc = LibXML::Document.new();
   my $schema = $doc.createElement('sphinx:schema');
   dies-ok { $schema.appendChild( $schema ) }, 'self appendChild dies';
   # TEST
}

{
    use NativeCall;
    use LibXML::Native;
    my $doc = LibXML::Document.new();
    my $attr = $doc.createAttribute('test','bar');
    my $ent = $doc.createEntityReference('foo');
    is $ent.Str, '&foo;', 'createEntityReference';
    my $text = $doc.createTextNode('baz');
    $attr.appendChild($ent);
    $attr.appendChild($text);
    # TEST
    is($attr.gist, 'test="bar&foo;baz"', ' TODO : Add test name');
}

{
    my $string = q:to<EOF>;
<r>
  <a/>
	  <b/>
  <![CDATA[

  ]]>
  <!-- foo -->
  <![CDATA[
    x
  ]]>
  <?foo bar?>
  <c/>
  text
</r>
EOF

    # TEST:$count=2;
    for $string -> $arg_to_parse
    {
        my $doc = LibXML.load: :string($arg_to_parse);
        my $r = $doc.getDocumentElement;
        # TEST*$count
        ok($r, ' TODO : Add test name');
        my @nonblank = $r.nonBlankChildNodes;
        # TEST*$count
        is(join(',',@nonblank.map(*.nodeName)), 'a,b,#comment,#cdata-section,foo,c,#text', ' TODO : Add test name' );
        # TEST*$count
        is($r.firstChild.nodeName, '#text', ' TODO : Add test name');

        my @all = $r.childNodes;
        # TEST*$count
        is(join(',', @all.map(*.nodeName)), '#text,a,#text,b,#text,#cdata-section,#text,#comment,#text,#cdata-section,#text,foo,#text,c,#text', ' TODO : Add test name' );

        my $f = $r.firstNonBlankChild;
        my $p;
        # TEST*$count
        is($f.nodeName, 'a', ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        is($f.previousSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( !$f.previousNonBlankSibling, ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        is($f.nodeName, 'b', ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        ok($f.isa('LibXML::Comment'), ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        ok($f.isa('LibXML::CDATA'), ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        ok($f.isa('LibXML::PI'), ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        is($f.nodeName, 'c', ' TODO : Add test name');
        # TEST*$count
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        # TEST*$count
        is($f.nodeName, '#text', ' TODO : Add test name');
        # TEST*$count
        is($f.nodeValue, "\n  text\n", ' TODO : Add test name');
        # TEST*$count
        ok(!$f.nextSibling, ' TODO : Add test name');
        # TEST*$count
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $f=$f.nextNonBlankSibling;
        # TEST*$count
        ok(!defined($f), ' TODO : Add test name');

    }
}

{
    # RT #94149
    # https://rt.cpan.org/Ticket/Display.html?id=94149

    my $orig = LibXML::Text.new: :content('Double ');
    my $ret = $orig.addSibling(LibXML::Text.new: :content('Free'));
    # TEST
    is( $ret.textContent, 'Double Free', 'merge text nodes with addSibling' );
}
