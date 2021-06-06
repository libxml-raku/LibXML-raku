##
# this test checks the DOM Node interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

use v6;
use Test;
plan 202;

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

    is($node, $xmlstring, ' TODO : Add test name');
    is($node.nodeType, +XML_ELEMENT_NODE, ' TODO : Add test name');
    is($node.nodeName, "foo", ' TODO : Add test name');
    ok(!defined( $node.nodeValue ), ' TODO : Add test name');
    ok($node.hasChildNodes, ' TODO : Add test name');
    is($node.textContent, "bar&foo bar", ' TODO : Add test name');

    {
        my @children = $node.childNodes;
        is( +@children, 5, ' TODO : Add test name' );
        is( @children[0].nodeType, +XML_TEXT_NODE, ' TODO : Add test name' );
        is( @children[0].nodeValue, "bar", ' TODO : Add test name' );
        is( @children[4].nodeType, +XML_CDATA_SECTION_NODE, ' TODO : Add test name' );
        is( @children[4].nodeValue, "&foo bar", ' TODO : Add test name' );

        my $fc = $node.firstChild;
        ok( $fc, ' TODO : Add test name' );
        ok( $fc.isSameNode(@children[0]), ' TODO : Add test name');
        ok( !defined($fc.baseURI), ' TODO : Add test name' );

        my $od = $fc.ownerDocument;
        ok( $od, ' TODO : Add test name' );
        ok( $od.isSameNode($doc), ' TODO : Add test name');

        my $xc = $fc.nextSibling;
        ok( $xc, ' TODO : Add test name' );
        ok( $xc.isSameNode(@children[1]), ' TODO : Add test name' );

        $fc = $node.lastChild;
        ok( $fc, ' TODO : Add test name' );
        ok( $fc.isSameNode(@children[4]), ' TODO : Add test name');

        $xc = $fc.previousSibling;
        ok( $xc, ' TODO : Add test name' );
        ok( $xc.isSameNode(@children[3]), ' TODO : Add test name' );
        $rnode = $xc;

        $xc = $fc.parentNode;
        ok( $xc, ' TODO : Add test name' );
        ok( $xc.isSameNode($node), ' TODO : Add test name' );

        $xc = @children[2];
        {
            # 1.2 Attribute Node
            ok( $xc.hasAttributes, 'hasAttributes' );
            my $attributes = $xc.attributes;
            ok( $attributes, 'got attributes' );

            is( +$attributes, 1, ' TODO : Add test name' );
            for $attributes<foo>, $xc.getChildrenByLocalName('@foo')[0] -> $attr {
                is( $attr, 'foobar', ' TODO : Add test name' );
                is( $attr.nodeType, +XML_ATTRIBUTE_NODE, ' TODO : Add test name' );
                is( $attr.nodeName, "foo", ' TODO : Add test name' );
                is( $attr.nodeValue, "foobar", ' TODO : Add test name' );
                is-deeply( $attr.hasChildNodes, False, 'hasChildNodes');
                }
        }

        {
            my $attributes := $xc.attributes;
            is( + $attributes, 1, ' TODO : Add test name' );
        }

        {
            my %kids = $node.childNodes.Hash;
            is-deeply %kids.keys.sort, ("bar", "comment()", "foobar", "text()");
            is %kids<foobar>[0].Str, "<foobar/>";
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
            is( $xnode, '<foo xmlns:x="http://ns" aaa="AAA" x:bbb="BBB"/>', ' TODO : Add test name' );
            is( $xnode.nodeName, "foo", ' TODO : Add test name' );
            ok( ! $xnode.hasChildNodes, ' TODO : Add test name' );
	    is( $xnode.getAttribute('aaa'),'AAA', ' TODO : Add test name' );

	    is( $xnode.getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            $xnode = $cnode.cloneNode(:deep);
            ok( $xnode, ' TODO : Add test name' );
            is( $xnode.nodeName, "foo", ' TODO : Add test name' );
            ok( $xnode.hasChildNodes, 'hasChildNodes' );
	    is( $xnode.getAttribute('aaa'),'AAA', ' TODO : Add test name' );
	    is( $xnode.getAttributeNS('http://ns','bbb'),'BBB', ' TODO : Add test name' );

            my @cn = $xnode.childNodes;
            ok( @cn, 'childNodes' );
            is( +@cn, 1, 'childNodfes');
            is( @cn[0].nodeName, "bar", 'first child node' );
            ok( !@cn[0].isSameNode( $c1node ), ' TODO : Add test name' );

            # clone namespaced elements
            my $nsnode = $doc.createElementNS( "fooNS", "foo:bar" );

            my $cnsnode = $nsnode.cloneNode();
            is( $cnsnode.nodeName, "foo:bar", ' TODO : Add test name' );
            ok( $cnsnode.localNS(), ' TODO : Add test name' );
            is( $cnsnode.namespaceURI(), 'fooNS', ' TODO : Add test name' );

            # clone namespaced elements (recursive)
            my $c2nsnode = $nsnode.cloneNode(:deep);
            is( $c2nsnode.Str, $nsnode.Str, ' TODO : Add test name' );
        }

        # 1.3 Node Value
        my $string2 = "<foo>bar<tag>foo</tag></foo>";
        {
            my $doc2 = $parser.parse: :string( $string2 );
            my $root = $doc2.documentElement;
            ok( ! defined($root.nodeValue), ' TODO : Add test name' );
            is( $root.textContent, "barfoo", ' TODO : Add test name');
        }
    }

    {
        my $children = $node.childNodes;
        ok( defined($children), ' TODO : Add test name' );
        isa-ok( $children, "LibXML::Node::List", ' TODO : Add test name' );
        is $children.first, 'bar';
        is $children[0].xpath-key, 'text()';
        is-deeply $children.Hash.keys.sort, ('bar', 'comment()', 'foobar', 'text()');
        is $children<comment()>, '<!--foo-->';
        is $children.tail, '<![CDATA[&foo bar]]>';
    }


    # 2. (Child) Node Manipulation

    # 2.1 Valid Operations

    {
        # 2.1.1 Single Node

        my $inode = $doc.createElement("kungfoo"); # already tested
        my $jnode = $doc.createElement("kungfoo");
        my $xn = $node.insertBefore($inode, $rnode);
        ok( $xn, ' TODO : Add test name' );
        ok( $xn.isSameNode($inode), ' TODO : Add test name' );

        $node.insertBefore( $jnode, LibXML::Node );
        my $children := $node.childNodes();
        my $n = 0; $n++ for $children;
        is $n, 7, 'iterator';
        $n = 0; $n++ for $children;
        is $n, 7, 'iterator';

        my @ta  = $node.childNodes();
        $xn = pop @ta;
        ok( $xn.isSameNode( $jnode ), ' TODO : Add test name' );

        $jnode.unbindNode;
        $node.Str;

        my @cn = $node.childNodes;
        is(+@cn, 6, ' TODO : Add test name');
        ok( @cn[3].isSameNode($inode), ' TODO : Add test name' );

        $xn = $node.removeChild($inode);
        ok($xn, ' TODO : Add test name');
        ok($xn.isSameNode($inode), ' TODO : Add test name');

        @cn = $node.childNodes;
        is(+@cn, 5, ' TODO : Add test name');
        ok( @cn[3].isSameNode($rnode), ' TODO : Add test name' );

        $xn = $node.appendChild($inode);
        ok($xn, ' TODO : Add test name');
        ok($xn.isSameNode($inode), ' TODO : Add test name');
        ok($xn.isSameNode($node.lastChild), ' TODO : Add test name');

        $xn = $node.removeChild($inode);
        ok($xn, ' TODO : Add test name');
        ok($xn.isSameNode($inode), ' TODO : Add test name');
        ok(@cn.tail.isSameNode($node.lastChild), ' TODO : Add test name');

        $xn = $node.replaceChild( $inode, $rnode );
        ok($xn, ' TODO : Add test name');
        ok($xn.isSameNode($rnode), ' TODO : Add test name');

        my @cn2 = $node.childNodes;
        is(+@cn, 5, ' TODO : Add test name');
        ok( @cn2[3].isSameNode($inode), ' TODO : Add test name' );
    }

    {
        # insertAfter Tests
        my $anode = $doc.createElement("a");
        my $bnode = $doc.createElement("b");
        my $cnode = $doc.createElement("c");
        my $dnode = $doc.createElement("d");

        $anode.insertAfter( $bnode, LibXML::Node );
        is( $anode.Str(), '<a><b/></a>', ' TODO : Add test name' );

        $anode.insertAfter( $dnode, LibXML::Node );
        is( $anode.Str(), '<a><b/><d/></a>', ' TODO : Add test name' );

        $anode.insertAfter( $cnode, $bnode );
        is( $anode.Str(), '<a><b/><c/><d/></a>', ' TODO : Add test name' );

    }

    {
        my ($inode, $jnode );

        $inode = $doc.createElement("kungfoo"); # already tested
        $jnode = $doc.createElement("foobar");

        my $xn = $inode.insertBefore( $jnode, LibXML::Node);
        ok( $xn, ' TODO : Add test name' );
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
        ok $node1.getOwner.isSameNode($frag), 'owner is fragment';
        ok $node1.getOwnerDocument.isSameNode($doc), 'ownerDocument';

        my $xn = $node.appendChild( $frag );

        ok($xn, ' TODO : Add test name');
        my @cn2 = $node.childNodes;
        is(+@cn2, 7, ' TODO : Add test name');
        ok(@cn2[*-1].isSameNode($node2), ' TODO : Add test name');
        ok(@cn2[*-2].isSameNode($node1), ' TODO : Add test name');

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );
        @cn2 = $node.childNodes;
        is(+@cn2, 5, ' TODO : Add test name');

        $xn = $node.replaceChild( $frag, @cn[3] );

        ok($xn, ' TODO : Add test name');
        ok($xn.isSameNode(@cn[3]), ' TODO : Add test name');
        @cn2 = $node.childNodes;
        is(+@cn2, 6, ' TODO : Add test name');

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );
        $frag.addNewChild( Str, 'baz' );

        $xn = $node.insertBefore( $frag, @cn[0] );
        ok($xn, ' TODO : Add test name');
        ok($node1.isSameNode($node.firstChild), ' TODO : Add test name');
        @cn2 = $node.childNodes;
        is(+@cn2, 7, ' TODO : Add test name');

        $node.insertBefore( $frag.new, @cn[2]);
        @cn2 = $node.childNodes;
        is(+@cn2, 7, ' TODO : Add test name');
        dies-ok {$node.insertBefore( $frag, @cn[2].clone);}
    }

    # 2.2 Invalid Operations


    # 2.3 DOM extensions
    {
        my $string = "<foo><bar/>com</foo>";
        my $doc = LibXML.parse: :$string;
        my $elem= $doc.documentElement;
        is( $elem, '<foo><bar/>com</foo>', ' TODO : Add test name' );
        ok( $elem.hasChildNodes, 'hasChildNodes' );
        my $frag = $elem.removeChildNodes;
        isa-ok $frag, 'LibXML::DocumentFragment', 'removed child nodes';
        is $frag, '<bar/>com', 'removed child nodes';
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


    ok($elem, ' TODO : Add test name');
    is($elem.nodeName, $pre~":"~$name, ' TODO : Add test name');
    is($elem.namespaceURI, $URI, ' TODO : Add test name');
    is($elem.prefix, $pre, ' TODO : Add test name');
    is($elem.localname, $name, ' TODO : Add test name' );


    is( $elem.lookupNamespacePrefix( $URI ), $pre, ' TODO : Add test name');
    is( $elem.lookupNamespaceURI( $pre ), $URI, ' TODO : Add test name');

    my @ns = $elem.getNamespaces;
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
    ok(@cn, ' TODO : Add test name');
    is( +@cn, 1, ' TODO : Add test name' );
    ok(@cn[0].isSameNode($e3), ' TODO : Add test name');
    ok($x.isSameNode($e2), ' TODO : Add test name');

    $e3.addSibling( $e2 );
    @cn = $e1.childNodes;
    is( +@cn, 2, ' TODO : Add test name' );
    ok(@cn[0].isSameNode($e3), ' TODO : Add test name');
    ok(@cn[1].isSameNode($e2), ' TODO : Add test name');
}

# 6.   implicit attribute manipulation

{
    my $parser = LibXML.new();
    my $doc = $parser.parse: :string( '<foo bar="foo"/>' );
    my $root = $doc.documentElement;
    my $attributes := $root.attributes;
    is( +$attributes, 1, ' TODO : Add test name');
    ok($attributes, ' TODO : Add test name');
    my $newAttr = $doc.createAttribute( "kung", "foo" );
    # as mandated by W3C DOM
    lives-ok {$newAttr.attributes}, 'node attributes';
    $attributes.setNamedItem( $newAttr );
    my %att := $root.attributes;
    ok(%att, ' TODO : Add test name');
    is( +%att, 2, ' TODO : Add test name');
    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "foo" );

    $attributes.setNamedItem($newAttr);
    %att := $root.attributes;
    ok(%att, ' TODO : Add test name');
    is( +%att.keys, 3, ' TODO : Add test name');

    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "bar" );
    $attributes.setNamedItem($newAttr);
    ok(%att, ' TODO : Add test name');
    is( +%att, 3, ' TODO : Add test name');
    is(%att<x:kung>, $newAttr.nodeValue, ' TODO : Add test name');
    $attributes.removeNamedItem( "x:kung");

    is( +%att, 2, ' TODO : Add test name');
    is($attributes.elems, 2, ' TODO : Add test name');
}

# 7. importing and adopting

{
    my $parser = LibXML.new;
    my $doc1 = $parser.parse: :string( "<foo>bar<foobar/></foo>" );
    my $doc2 = LibXML::Document.new;


    ok( $doc1 && $doc2, ' TODO : Add test name' );
    my $rnode1 = $doc1.documentElement;
    ok( $rnode1, ' TODO : Add test name' );
    my $rnode2 = $doc2.importNode( $rnode1 );
    ok( ! $rnode2.isSameNode( $rnode1 ), ' TODO : Add test name' ) ;
    $doc2.setDocumentElement( $rnode2 );
    my $node = $rnode2.cloneNode();
    ok( $node, ' TODO : Add test name' );
    my $cndoc = $node.ownerDocument;
    ok( $cndoc.defined, ' TODO : Add test name' );
    ok( $cndoc.isSameNode( $doc2 ), ' TODO : Add test name' );

    my $xnode = LibXML::Element.new: :name<test>;

    my $node2 = $doc2.importNode($xnode);
    ok( $node2, ' TODO : Add test name' );
    my $cndoc2 = $node2.ownerDocument;
    ok( $cndoc2, ' TODO : Add test name' );
    ok( $cndoc2.isSameNode( $doc2 ), ' TODO : Add test name' );

    my $doc3 = LibXML::Document.new;
    my $node3 = $doc3.adoptNode( $xnode );
    ok( $node3, ' TODO : Add test name' );
    ok( $xnode.isSameNode( $node3 ), ' TODO : Add test name' );
    ok $node3.ownerDocument.defined, "have owner document";
    ok( $doc3.isSameNode( $node3.ownerDocument ), ' TODO : Add test name' );

    my $xnode2 = LibXML::Element.new: :name<test>;
    $xnode2.setOwnerDocument( $doc3 ); # alternate version of adopt node
    ok( $xnode2.ownerDocument, 'setOwnerDocument' );
    ok( $doc3.isSameNode( $xnode2.ownerDocument ), 'setOwnerDocument' );
}

{
  # appending empty fragment
  my $doc = LibXML::Document.new();
  my $frag = $doc.createDocumentFragment();
  my $root = $doc.createElement( 'foo' );
  my $r = $root.appendChild( $frag );
  nok( $r, 'append empty fragment' );
}

{
   my $doc = LibXML::Document.new();
   my $schema = $doc.createElement('sphinx:schema');
   dies-ok { $schema.appendChild( $schema ) }, 'self appendChild dies';
}

{
    use NativeCall;
    use LibXML::Raw;
    my $doc = LibXML::Document.new();
    my $attr = $doc.createAttribute('test','bar');
    my $ent = $doc.createEntityReference('foo');
    is $ent.Str, '&foo;', 'createEntityReference';
    my $text = $doc.createTextNode('baz');
    $attr.appendChild($ent);
    $attr.appendChild($text);
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

    {
        my $doc = LibXML.load: :$string;
        my $r = $doc.getDocumentElement;
        ok($r, ' TODO : Add test name');
        my @nonblank = $r.nonBlankChildNodes;
        is(join(',',@nonblank.map(*.ast-key)), 'a,b,#comment,#cdata,?foo,c,#text', 'ast-key' );
        is(join(',',@nonblank.map(*.xpath-key)), 'a,b,comment(),text(),processing-instruction(),c,text()', 'xpath-key' );
        is(join(',',@nonblank.map(*.nodeName)), 'a,b,#comment,#cdata-section,foo,c,#text', 'nodeName' );
        is +@nonblank.grep(*.isBlank), 0, '*.isBlank';
        is($r.firstChild.nodeName, '#text', ' TODO : Add test name');
        is $r.getChildrenByTagName('foo').map(*.nodeName).join, 'foo';  
        is $r.getChildrenByLocalName('?foo').map(*.nodeName).join, 'foo';  
        is $r.getChildrenByLocalName('?*').map(*.nodeName).join, 'foo';  
        is $r.getChildrenByLocalName('#comment').map(*.nodeName).join, '#comment';  
        is $r.getChildrenByTagName('#comment').map(*.nodeName).join, '#comment';  

        my @all = $r.childNodes;
        is(join(',', @all.map(*.ast-key)), '#text,a,#text,b,#text,#cdata,#text,#comment,#text,#cdata,#text,?foo,#text,c,#text', ' TODO : Add test name' );

        is-deeply $r.firstChild.isBlank, True, 'first blank child';

        my $f = $r.firstNonBlankChild;
        my $p;
        is($f.nodeName, 'a', ' TODO : Add test name');
        is-deeply $f.isBlank, False, '.isBlank() on  non-blank node';
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        is($f.previousSibling.nodeName, '#text', ' TODO : Add test name');
        ok( !$f.previousNonBlankSibling, ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is($f.nodeName, 'b', ' TODO : Add test name');
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok($f.isa('LibXML::Comment'), ' TODO : Add test name');
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok($f.isa('LibXML::CDATA'), ' TODO : Add test name');
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok($f.isa('LibXML::PI'), ' TODO : Add test name');
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is($f.nodeName, 'c', ' TODO : Add test name');
        is($f.nextSibling.nodeName, '#text', ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is($f.nodeName, '#text', ' TODO : Add test name');
        is($f.nodeValue, "\n  text\n", ' TODO : Add test name');
        ok(!$f.nextSibling, ' TODO : Add test name');
        ok( $f.previousNonBlankSibling.isSameNode($p), ' TODO : Add test name' );

        $f=$f.nextNonBlankSibling;
        ok(!defined($f), ' TODO : Add test name');

    }
}

{
    # RT #94149
    # https://rt.cpan.org/Ticket/Display.html?id=94149

    my $orig = LibXML::Text.new: :content('Double ');
    my $ret = $orig.addSibling(LibXML::Text.new: :content('Free'));
    is( $ret.textContent, 'Double Free', 'merge text nodes with addSibling' );
}
