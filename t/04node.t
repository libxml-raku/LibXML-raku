##
# this test checks the DOM Node interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

use v6;
use Test;
plan 11;

use LibXML;
use LibXML::Enums;

my $xmlstring = q{<foo>bar<foobar/><bar foo="foobar"/><!--foo--><![CDATA[&foo bar]]></foo>};

my LibXML $parser .= new;
my $doc    = $parser.parse: :string( $xmlstring );

subtest 'Standalone Without NameSpaces', {
    my $node = $doc.documentElement;
    my $rnode;

    is $node, $xmlstring;
    is $node.nodeType, +XML_ELEMENT_NODE;
    is $node.nodeName, "foo";
    ok !defined( $node.nodeValue );
    ok $node.hasChildNodes;
    is $node.textContent, "bar&foo bar";

    subtest 'node attributes', {
        my @children = $node.childNodes;
        is +@children, 5;
        is @children[0].nodeType, +XML_TEXT_NODE;
        is @children[0].nodeValue, "bar";
        is @children[4].nodeType, +XML_CDATA_SECTION_NODE;
        is @children[4].nodeValue, "&foo bar";

        my $fc = $node.firstChild;
        ok $fc;
        ok $fc.isSameNode(@children[0]);
        ok !defined($fc.baseURI);

        my $od = $fc.ownerDocument;
        ok $od;
        ok $od.isSameNode($doc);

        my $xc = $fc.nextSibling;
        ok $xc;
        ok $xc.isSameNode(@children[1]);

        $fc = $node.lastChild;
        ok $fc;
        ok $fc.isSameNode(@children[4]);

        $xc = $fc.previousSibling;
        ok $xc;
        ok $xc.isSameNode(@children[3]);
        $rnode = $xc;

        $xc = $fc.parentNode;
        ok $xc;
        ok $xc.isSameNode($node);

        $xc = @children[2];
        subtest 'attribute node', {
            ok $xc.hasAttributes, 'hasAttributes';
            my $attributes = $xc.attributes;
            ok $attributes, 'got attributes';

            is +$attributes, 1;
            for $attributes<foo>, $xc.getChildrenByLocalName('@foo')[0] -> $attr {
                is $attr, 'foobar';
                is $attr.nodeType, +XML_ATTRIBUTE_NODE;
                is $attr.nodeName, "foo";
                is $attr.nodeValue, "foobar";
                is-deeply( $attr.hasChildNodes, False, 'hasChildNodes');
            }

            {
                my $attributes := $xc.attributes;
                is + $attributes, 1;
            }

            {
                my %kids = $node.childNodes.Hash;
                is-deeply %kids.keys.sort, ("bar", "comment()", "foobar", "text()");
                is %kids<foobar>[0].Str, "<foobar/>";
            }
        }

        subtest 'node cloning', {
            my $cnode  = $doc.createElement("foo");
	    $cnode.setAttribute('aaa','AAA');
	    $cnode.setAttributeNS('http://ns','x:bbb','BBB');
            my $c1node = $doc.createElement("bar");
            $cnode.appendChild( $c1node );
            is $cnode, '<foo xmlns:x="http://ns" aaa="AAA" x:bbb="BBB"><bar/></foo>';

            my $xnode = $cnode.cloneNode();
            is $xnode, '<foo xmlns:x="http://ns" aaa="AAA" x:bbb="BBB"/>';
            is $xnode.nodeName, "foo";
            ok ! $xnode.hasChildNodes;
	    is $xnode.getAttribute('aaa'),'AAA';

	    is $xnode.getAttributeNS('http://ns','bbb'),'BBB';

            $xnode = $cnode.cloneNode(:deep);
            ok $xnode;
            is $xnode.nodeName, "foo";
            ok $xnode.hasChildNodes, 'hasChildNodes';
	    is $xnode.getAttribute('aaa'),'AAA';
	    is $xnode.getAttributeNS('http://ns','bbb'),'BBB';

            my @cn = $xnode.childNodes;
            ok @cn, 'childNodes' ;
            is +@cn, 1, 'childNodes';
            is @cn[0].nodeName, "bar", 'first child node';
            ok !@cn[0].isSameNode( $c1node );

            # clone namespaced elements
            my $nsnode = $doc.createElementNS( "fooNS", "foo:bar" );

            my $cnsnode = $nsnode.cloneNode();
            is $cnsnode.nodeName, "foo:bar";
            ok $cnsnode.localNS();
            is $cnsnode.namespaceURI(), 'fooNS';

            # clone namespaced elements (recursive)
            my $c2nsnode = $nsnode.cloneNode(:deep);
            is $c2nsnode.Str, $nsnode.Str;
        }

        my $string2 = "<foo>bar<tag>foo</tag></foo>";
        subtest 'node value', {
            my $doc2 = $parser.parse: :string( $string2 );
            my $root = $doc2.documentElement;
            ok ! defined($root.nodeValue);
            is $root.textContent, "barfoo";
        }
    }

    subtest 'node children', {
        my $children = $node.childNodes;
        ok defined($children);
        isa-ok $children, "LibXML::Node::List";
        is $children.first, 'bar';
        is $children[0].xpath-key, 'text()';
        is-deeply $children.Hash.keys.sort, ('bar', 'comment()', 'foobar', 'text()');
        is $children<comment()>, '<!--foo-->';
        is $children.tail, '<![CDATA[&foo bar]]>';
    }


    subtest '(Child) Node Manipulation', {

        subtest 'valid operations', {
            my $inode = $doc.createElement("kungfoo"); # already tested
            my $jnode = $doc.createElement("kungfoo");
            my $xn = $node.insertBefore($inode, $rnode);
            ok $xn;
            ok $xn.isSameNode($inode);

            $node.insertBefore( $jnode, LibXML::Node );
            my $children := $node.childNodes();
            my $n = 0; $n++ for $children;
            is $n, 7, 'iterator';
            $n = 0; $n++ for $children;
            is $n, 7, 'iterator';

            my @ta  = $node.childNodes();
            $xn = pop @ta;
            ok $xn.isSameNode( $jnode );

            $jnode.unbindNode;
            $node.Str;

            my @cn = $node.childNodes;
            is +@cn, 6;
            ok @cn[3].isSameNode($inode);

            $xn = $node.removeChild($inode);
            ok $xn;
            ok $xn.isSameNode($inode);

            @cn = $node.childNodes;
            is +@cn, 5;
            ok @cn[3].isSameNode($rnode);

            $xn = $node.appendChild($inode);
            ok $xn;
            ok $xn.isSameNode($inode);
            ok $xn.isSameNode($node.lastChild);

            $xn = $node.removeChild($inode);
            ok $xn;
            ok $xn.isSameNode($inode);
            ok @cn.tail.isSameNode($node.lastChild);

            $xn = $node.replaceChild( $inode, $rnode );
            ok $xn;
            ok $xn.isSameNode($rnode);

            my @cn2 = $node.childNodes;
            is +@cn, 5;
            ok @cn2[3].isSameNode($inode);
        }
    }

    subtest 'insertAfter', {
        my $anode = $doc.createElement("a");
        my $bnode = $doc.createElement("b");
        my $cnode = $doc.createElement("c");
        my $dnode = $doc.createElement("d");

        $anode.insertAfter( $bnode, LibXML::Node );
        is $anode.Str(), '<a><b/></a>';

        $anode.insertAfter( $dnode, LibXML::Node );
        is $anode.Str(), '<a><b/><d/></a>';

        $anode.insertAfter( $cnode, $bnode );
        is $anode.Str(), '<a><b/><c/><d/></a>';

    }

    subtest 'createElement', {
        my ($inode, $jnode );

        $inode = $doc.createElement("kungfoo"); # already tested
        $jnode = $doc.createElement("foobar");

        my $xn = $inode.insertBefore( $jnode, LibXML::Node);
        ok $xn;
        ok $xn.isSameNode( $jnode );
    }

    subtest 'document fragment', {
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

        ok $xn;
        my @cn2 = $node.childNodes;
        is +@cn2, 7;
        ok @cn2[*-1].isSameNode($node2);
        ok @cn2[*-2].isSameNode($node1);

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );
        @cn2 = $node.childNodes;
        is +@cn2, 5;

        $xn = $node.replaceChild( $frag, @cn[3] );

        ok $xn;
        ok $xn.isSameNode(@cn[3]);
        @cn2 = $node.childNodes;
        is +@cn2, 6;

        $frag.appendChild( $node1 );
        $frag.appendChild( $node2 );
        $frag.addNewChild( Str, 'baz' );

        $xn = $node.insertBefore( $frag, @cn[0] );
        ok $xn;
        ok $node1.isSameNode($node.firstChild);
        @cn2 = $node.childNodes;
        is +@cn2, 7;

        $node.insertBefore( $frag.new, @cn[2]);
        @cn2 = $node.childNodes;
        is +@cn2, 7;
        dies-ok {$node.insertBefore( $frag, @cn[2].clone);}
    }

    subtest 'DOM extensions', {
        my $string = "<foo><bar/>com</foo>";
        my $doc = LibXML.parse: :$string;
        my $elem= $doc.documentElement;
        is $elem, '<foo><bar/>com</foo>';
        ok $elem.hasChildNodes, 'hasChildNodes';
        my $frag = $elem.removeChildNodes;
        isa-ok $frag, 'LibXML::DocumentFragment', 'removed child nodes';
        is $frag, '<bar/>com', 'removed child nodes';
        nok $elem.hasChildNodes, 'hasChildNodes after removal';
        $elem.Str;
    }
}

subtest 'Standalone With NameSpaces', {
    my $doc = LibXML::Document.new();
    my $URI ="http://kungfoo";
    my $pre = "foo";
    my $name= "bar";

    my $elem = $doc.createElementNS($URI, $pre~":"~$name);

    ok $elem.defined;
    is $elem.nodeName, $pre~":"~$name;
    is $elem.namespaceURI, $URI;
    is $elem.prefix, $pre;
    is $elem.localname, $name;


    is $elem.lookupNamespacePrefix( $URI ), $pre;
    is $elem.lookupNamespaceURI( $pre ), $URI;

    my @ns = $elem.getNamespaces;
    is +@ns, 1;
}


subtest 'Document Switching', {
    my $docA = LibXML::Document.new;
    subtest 'simple document', {
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
    ok $xroot.isSameNode($docA);

}

subtest 'libxml2 specials', {
    my $docA = LibXML::Document.new;
    my $e1   = $docA.createElement( "A" );
    my $e2   = $docA.createElement( "B" );
    my $e3   = $docA.createElement( "C" );

    $e1.appendChild( $e2 );
    my $x = $e2.replaceNode( $e3 );
    my @cn = $e1.childNodes;
    ok @cn;
    is +@cn, 1;
    ok @cn[0].isSameNode($e3);
    ok $x.isSameNode($e2);

    $e3.addSibling( $e2 );
    @cn = $e1.childNodes;
    is +@cn, 2;
    ok @cn[0].isSameNode($e3);
    ok @cn[1].isSameNode($e2);
}

subtest 'implicit attribute manipulation', {
    my $parser = LibXML.new();
    my $doc = $parser.parse: :string( '<foo bar="foo"/>' );
    my $root = $doc.documentElement;
    my $attributes := $root.attributes;
    is +$attributes, 1;
    ok $attributes;
    my $newAttr = $doc.createAttribute( "kung", "foo" );
    # as mandated by W3C DOM
    lives-ok {$newAttr.attributes}, 'node attributes';
    $attributes.setNamedItem( $newAttr );
    my %att := $root.attributes;
    ok %att;
    is +%att, 2;
    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "foo" );

    $attributes.setNamedItem($newAttr);
    %att := $root.attributes;
    ok %att;
    is +%att.keys, 3;

    $newAttr = $doc.createAttributeNS( "http://kungfoo", "x:kung", "bar" );
    $attributes.setNamedItem($newAttr);
    ok %att;
    is +%att, 3;
    is %att<x:kung>, $newAttr.nodeValue;
    $attributes.removeNamedItem( "x:kung");

    is +%att, 2;
    is $attributes.elems, 2;
}

subtest 'importing and adopting', {
    my $parser = LibXML.new;
    my $doc1 = $parser.parse: :string( "<foo>bar<foobar/></foo>" );
    my $doc2 = LibXML::Document.new;


    ok $doc1 && $doc2;
    my $rnode1 = $doc1.documentElement;
    ok $rnode1;
    my $rnode2 = $doc2.importNode( $rnode1 );
    ok( ! $rnode2.isSameNode( $rnode1 ); ) ;
    $doc2.setDocumentElement( $rnode2 );
    my $node = $rnode2.cloneNode();
    ok $node;
    my $cndoc = $node.ownerDocument;
    ok $cndoc.defined;
    ok $cndoc.isSameNode( $doc2 );

    my $xnode = LibXML::Element.new: :name<test>;

    my $node2 = $doc2.importNode($xnode);
    ok $node2;
    my $cndoc2 = $node2.ownerDocument;
    ok $cndoc2;
    ok $cndoc2.isSameNode( $doc2 );

    my $doc3 = LibXML::Document.new;
    my $node3 = $doc3.adoptNode( $xnode );
    ok $node3;
    ok $xnode.isSameNode( $node3 );
    ok $node3.ownerDocument.defined, "have owner document";
    ok $doc3.isSameNode( $node3.ownerDocument );

    my $xnode2 = LibXML::Element.new: :name<test>;
    $xnode2.setOwnerDocument( $doc3 ); # alternate version of adopt node
    ok $xnode2.ownerDocument, 'setOwnerDocument';
    ok $doc3.isSameNode( $xnode2.ownerDocument ), 'setOwnerDocument';
}

subtest 'appending empty fragment', {
  #
  my $doc = LibXML::Document.new();
  my $frag = $doc.createDocumentFragment();
  my $root = $doc.createElement( 'foo' );
  my $r = $root.appendChild( $frag );
  nok $r, 'append empty fragment'
}

subtest 'self append', {
   my $doc = LibXML::Document.new();
   my $schema = $doc.createElement('sphinx:schema');
   dies-ok { $schema.appendChild( $schema ) }, 'self appendChild dies';
}

subtest 'entity reference', {
    use NativeCall;
    my $doc = LibXML::Document.new();
    my $attr = $doc.createAttribute('test','bar');
    my $ent = $doc.createEntityReference('foo');
    is $ent.Str, '&foo;', 'createEntityReference';
    my $text = $doc.createTextNode('baz');
    $attr.appendChild($ent);
    $attr.appendChild($text);
    is $attr.gist, 'test="bar&foo;baz"';
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

    subtest 'child accessors', {
        my $doc = LibXML.load: :$string;
        my $r = $doc.getDocumentElement;
        ok $r;
        my @nonblank = $r.nonBlankChildNodes;
        is join(',',@nonblank.map(*.ast-key)), 'a,b,#comment,#cdata,?foo,c,#text', 'ast-key';
        is join(',',@nonblank.map(*.xpath-key)), 'a,b,comment(),text(),processing-instruction(),c,text()', 'xpath-key';
        is join(',',@nonblank.map(*.nodeName)), 'a,b,#comment,#cdata-section,foo,c,#text', 'nodeName';
        is +@nonblank.grep(*.isBlank), 0, '*.isBlank';
        is $r.firstChild.nodeName, '#text';
        is $r.getChildrenByTagName('foo').map(*.nodeName).join, 'foo'; 
        is $r.getChildrenByLocalName('?foo').map(*.nodeName).join, 'foo'; 
        is $r.getChildrenByLocalName('?*').map(*.nodeName).join, 'foo'; 
        is $r.getChildrenByLocalName('#comment').map(*.nodeName).join, '#comment'; 
        is $r.getChildrenByTagName('#comment').map(*.nodeName).join, '#comment'; 

        my @all = $r.childNodes;
        is join(',', @all.map(*.ast-key)), '#text,a,#text,b,#text,#cdata,#text,#comment,#text,#cdata,#text,?foo,#text,c,#text';

        is-deeply $r.firstChild.isBlank, True, 'first blank child';

        my $f = $r.firstNonBlankChild;
        my $p;
        is $f.nodeName, 'a';
        is-deeply $f.isBlank, False, '.isBlank() on  non-blank node';
        is $f.nextSibling.nodeName, '#text';
        is $f.previousSibling.nodeName, '#text';
        ok !$f.previousNonBlankSibling;

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is $f.nodeName, 'b';
        is $f.nextSibling.nodeName, '#text';
        ok $f.previousNonBlankSibling.isSameNode($p);

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok $f.isa('LibXML::Comment');
        is $f.nextSibling.nodeName, '#text';
        ok $f.previousNonBlankSibling.isSameNode($p);

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok $f.isa('LibXML::CDATA');
        is $f.nextSibling.nodeName, '#text';
        ok $f.previousNonBlankSibling.isSameNode($p);

        $p = $f;
        $f=$f.nextNonBlankSibling;
        ok $f.isa('LibXML::PI');
        is $f.nextSibling.nodeName, '#text';
        ok $f.previousNonBlankSibling.isSameNode($p);

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is $f.nodeName, 'c';
        is $f.nextSibling.nodeName, '#text';
        ok $f.previousNonBlankSibling.isSameNode($p);

        $p = $f;
        $f=$f.nextNonBlankSibling;
        is $f.nodeName, '#text';
        is $f.nodeValue, "\n  text\n";
        ok !$f.nextSibling;
        ok $f.previousNonBlankSibling.isSameNode($p);

        $f=$f.nextNonBlankSibling;
        ok !defined($f);

    }
}

subtest 'Perl #94149', {
    # https://rt.cpan.org/Ticket/Display.html?id=94149

    my $orig = LibXML::Text.new: :content('Double ');
    my $ret = $orig.addSibling(LibXML::Text.new: :content('Free'));
    is $ret.textContent, 'Double Free', 'merge text nodes with addSibling'
}
