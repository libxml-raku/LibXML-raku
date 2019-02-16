use v6;
use Test;
##
# this test checks the DOM Document interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

# since all tests are run on a preparsed

plan 194;

use LibXML;
use LibXML::Enums;

sub is-empty-str(Str $s)
{
    return (!defined($s) or ($s.chars == 0));
}

# TEST:$c=0;
sub _check_element_node(LibXML::Node $node, Str $name, Str $blurb)
{

     ok($node, "$blurb - node was initialised");
     is($node.node.type, +XML_ELEMENT_NODE, "$blurb - node is an element node");
     is($node.node.name, $name, "$blurb - node has the right name.");
}

# TEST:$check-element-node=$c;

sub _check_created_element(LibXML::Document $doc, Str $given-name, Str $name, Str $blurb)
{
    return _check_element_node(
        $doc.createElement($given-name),
        $name,
        $blurb
    );
}
# TEST:$_check_created_element=$check-element-node;

sub _multi_arg_generic_count(LibXML::Document $doc, Str $method, List $params)
{

    my (List $meth_params, UInt $want_count, Str $blurb) = @$params;

    my @elems = $doc."$method"( |$meth_params );

    return is (+(@elems), $want_count, $blurb);
}

sub _generic_count(LibXML::Document $doc, Str $method, List $params)
{
    my (Str $name, UInt $want_count, Str $blurb) = @$params;

    return _multi_arg_generic_count(
        $doc, $method, [[$name], $want_count, $blurb, ],
    );
}

sub _count_local_name(LibXML::Document $doc, *@args)
{
    return _generic_count($doc, 'getElementsByLocalName', @args);
}

sub _count_tag_name(LibXML::Document $doc, *@args)
{
    return _generic_count($doc, 'getElementsByTagName', @args);
}

sub _count_children_by_local_name(LibXML::Document $doc, *@args)
{
    return _generic_count($doc, 'getChildrenByLocalName', @args);
}

sub _count_children_by_name(LibXML::Document $doc, *@args)
{
    return _generic_count($doc, 'getChildrenByTagName', @args);
}

sub _count_elements_by_name_ns(LibXML::Document $doc, Str $ns_and_name, UInt $want_count, Str $blurb)
{
    return _multi_arg_generic_count($doc, 'getElementsByTagNameNS',
        [$ns_and_name, $want_count, $blurb]
    );
}

sub _count_children_by_name_ns(LibXML::Document $doc, Str $ns_and_name, UInt $want_count, Str $blurb)
{
    return _multi_arg_generic_count($doc, 'getChildrenByTagNameNS',
        [$ns_and_name, $want_count, $blurb]
    );
}

{
    # Document Attributes

    my LibXML::Document $doc .= createDocument();
    # TEST
    ok($doc, 'document creation');

   # TEST
    ok( ! defined($doc.encoding), 'doc.encoding');
    # TEST
    is( $doc.version,  "1.0", 'doc.version' );
    # TEST
    is( $doc.standalone, -1, 'doc.standalone' );  # is the value we get for undefined,
                                 # actually the same as 0 but just not set.
    # TEST
    ok( !defined($doc.URI), 'doc.URI');  # should be set by default.
    # TEST
    is( $doc.compression, -1, 'doc.compression' ); # -1 indicates NO compression at all!
                                 # while 0 indicates just no zip compression
                                 # (big difference huh?)

    $doc.node.encoding = "iso-8859-1";
    # TEST
    is( $doc.encoding, "iso-8859-1", 'Encoding was set.' );

    $doc.version = "12.5";
    # TEST
    is( $doc.version, "12.5", 'Version was set.' );

    $doc.standalone = 1;
    # TEST
    is( $doc.standalone, 1, 'Standalone was set.' );

    $doc.baseURI = "localhost/here.xml";
    # TEST
    is( $doc.URI, "localhost/here.xml", 'URI is set.' );

    my $doc2 = LibXML::Document.createDocument(:version<1.1>, :encoding<iso-8859-2>);
    # TEST
    is( $doc2.encoding, "iso-8859-2", 'doc2 encoding was set.' );
    # TEST
    is( $doc2.version,  "1.1", 'doc2 version was set.' );
    # TEST
    is( $doc2.standalone,  -1, 'doc2 standalone' );
}

{
    # 2. Creating Elements
    my LibXML::Document $doc .= new();
    {
        my $node = $doc.createDocumentFragment();
        # TEST
        ok($node, '$doc.createDocumentFragment');
        # TEST
        is($node.node.type, +XML_DOCUMENT_FRAG_NODE, 'document fragment type');
    }

    # TEST*$_check_created_element
    _check_created_element($doc, 'foo', 'foo', 'Simple Element');

    {
        # document with encoding
        my LibXML::Document $encdoc .= new;
        $encdoc.encoding = "iso-8859-1";

        # TEST*$_check_created_element
        _check_created_element(
            $encdoc, 'foo', 'foo', 'Encdoc Element creation'
        );

        # SAX style document with encoding
        my %node_def = %(
            Name => "object",
            LocalName => "object",
            Prefix => "",
            NamespaceURI => "",
                       );

        # TEST*$_check_created_element
        _check_created_element(
            $encdoc, %node_def<Name>, 'object',
            'Encdoc element creation based on node_def->{name}',
        );
    }

    {
        # namespaced element test
        my $node = $doc.createElementNS( "http://kungfoo", "foo:bar" );
        is $node.node.nsDef, 'xmlns:foo="http://kungfoo"', 'Node namespace';
        # TEST
        is $node, '<foo:bar xmlns:foo="http://kungfoo"/>', '$doc.createElement';
        # TEST
        is($node.nodeType, +XML_ELEMENT_NODE, '$node.nodeType');
        # TEST
        is($node.nodeName, "foo:bar", '$node.nodeName');
        # TEST
        is($node.prefix, "foo", '$node.prefix');
        # TEST
        is($node.localname, "bar", '$node.localname');
        # TEST
        is($node.namespaceURI, "http://kungfoo", '$node.namespaceURI');
    }

    {
        # bad element creation
        # TEST:$badnames_count=5;
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createElement( $name );};
        }

    }

    {
        need LibXML::Text;
        my LibXML::Text:D $node = $doc.createTextNode( "foo" );
        # TEST
        is($node, 'foo', 'text Str');
        # TEST
        is($node.nodeType, +XML_TEXT_NODE, 'text node type' );
        # TEST
        is($node.nodeValue, "foo", 'text node value' );
    }

    {
        need LibXML::Comment;
        my LibXML::Comment:D $node = $doc.createComment( "foo" );
        # TEST
        is($node, '<!--foo-->', 'comment Str');
        # TEST
        is($node.nodeType, +XML_COMMENT_NODE, 'comment node type' );
        # TEST
        is($node.nodeValue, "foo", 'comment node value' );
        # TEST
        is($node.Str, "<!--foo-->", 'Comment node string');
    }

    {
        need LibXML::CDATASection;
        my LibXML::CDATASection:D $node = $doc.createCDATASection( "foo" );
        # TEST
        ok($node, '$doc.createCDATASection');
        # TEST
        is($node.nodeType, +XML_CDATA_SECTION_NODE, 'CDATA node type' );
        # TEST
        is($node.nodeValue, "foo", 'CDATA node value' );
        # TEST
        is($node.Str, "<![CDATA[foo]]>", 'CDATA node string');
    }

    # -> Create Attributes
    {
        need LibXML::Attr;
        need LibXML::Text;
        my LibXML::Attr:D $attr = $doc.createAttribute("foo", "bar");
        # TEST
        is($attr, ' foo="bar"', 'attr Str');
        # TEST
        is($attr.nodeType, +XML_ATTRIBUTE_NODE, 'attr nodeType' );
        # TEST
        is($attr.name, "foo", 'attr name');
        # TEST
        is($attr.value, "bar", 'attr value' );
        # TEST
        is-deeply($attr.hasChildNodes, False, 'att hasChildNodes');
        my  LibXML::Text:D $content = $attr.firstChild;
        # TEST
        is( $content, 'bar', 'attr content Str' );
        # TEST
        is( $content.nodeType, +XML_TEXT_NODE, 'attribute content is a text node' );
    }

    {
        # bad attribute creation
        # TEST:$badnames_count=5;
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createAttribute( $name, "bar" );}, "badd att name: $name";
        }

    }

    {
      need LibXML::Element;
      need LibXML::Attr;
      my LibXML::Element:D $elem = $doc.createElement('foo');
      my LibXML::Attr:D $attr = $doc.createAttribute('attr', 'e & f');
      $elem.setAttributeNode($attr);
      # TEST
      is($elem, '<foo attr="e &amp; f"/>', 'Elem with attribute added');
      $elem.removeAttribute('attr');
      $attr = $doc.createAttribute('attr2' => 'a & b');
      $elem.addChild($attr);
      # TEST
      is $elem, '<foo attr2="a &amp; b"/>', 'Elem replace attributes';
    }
    {
        dies-ok {
            my $attr = $doc.createAttributeNS("http://kungfoo", "kung:foo","bar");
        }, '$doc.createAttributeNS without root element - dies';

        my $root = $doc.createElement( "foo" );
        $doc.documentElement = $root;
        my $attr;
        lives-ok {
           $attr = $doc.createAttributeNS("http://kungfoo", "kung:foo","bar");
        };
        # TEST
        ok($attr, '$doc.createAttributeNS');
        # TEST
        is($attr.nodeName, "kung:foo", '$doc.createAttributeNS nodeName');
        # TEST
        is($attr.name,"foo", '$doc.createAttributeNS name' );
        # TEST
        is($attr.value, "bar", ' TODO : Add test name' );

        $attr.value = 'bar&amp;';
        # TEST
        is($attr.value, 'bar&amp;', ' TODO : Add test name' );
    }

    {
        # good attribute creation
        # TEST:$badnames_count=5;
        my @goodnames = ( "foo", "bar:baz");

        for @goodnames -> $name {
            lives-ok {$doc.createAttributeNS( Str, $name, "bar" );}, 'createAttributeNS with good name';
        }

    }
    {
        # bad attribute creation
        # TEST:$badnames_count=5;
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createAttributeNS( Str, $name, "bar" );}, 'createAttributeNS with bad name';
        }

    }

    # -> Create PIs
    {
        need LibXML::PI;
        my LibXML::PI:D $pi = $doc.createProcessingInstruction( "foo", "bar" );
        # TEST
        is($pi, '<?foo bar?>');
        # TEST
        is($pi.nodeType, +XML_PI_NODE, ' TODO : Add test name');
        # TEST
        is($pi.nodeName, "foo", ' TODO : Add test name');
        # TEST
        is($pi.string-value, "bar", ' TODO : Add test name');
        # TEST
        is($pi.content, "bar", ' TODO : Add test name');
    }

    {
        my $pi = $doc.createProcessingInstruction( "foo" );
        # TEST
        is($pi, '<?foo?>');
        # TEST
        is($pi.nodeType, +XML_PI_NODE, ' TODO : Add test name');
        # TEST
        is($pi.nodeName, "foo", ' TODO : Add test name');
        my $data = $pi.content;
        # undef or "" depending on libxml2 version
        # TEST
        ok( is-empty-str($data), ' TODO : Add test name' );
        $data = $pi.content;
        # TEST
        ok( is-empty-str($data), ' TODO : Add test name' );
        $pi.nodeValue = 'bar&amp;';
        # TEST
        is($pi.content, 'bar&amp;', ' TODO : Add test name');
        is $pi, '<?foo bar&amp;?>';
    }
}

skip("port remaining tests", 107);
=begin POD

{
    # Document Manipulation
    # -> Document Elements

    my $doc = LibXML::Document->new();
    my $node = $doc->createElement( "foo" );
    $doc->setDocumentElement( $node );
    my $tn = $doc->documentElement;
    # TEST
    ok($tn, ' TODO : Add test name');
    # TEST
    ok($node->isSameNode($tn), ' TODO : Add test name');

    my $node2 = $doc->createElement( "bar" );
    { my $warn;
      eval {
        local $SIG{__WARN__} = sub { $warn = 1 };
        # TEST
        ok( !defined($doc->appendChild($node2)), ' TODO : Add test name' );
      };
      # TEST
      ok(($@ or $warn), ' TODO : Add test name');
    }
    my @cn = $doc->childNodes;
    # TEST
    is( scalar(@cn) , 1, ' TODO : Add test name');
    # TEST
    ok($cn[0]->isSameNode($node), ' TODO : Add test name');

    eval {
      $doc->insertBefore($node2, $node);
    };
    # TEST
    ok ($@, ' TODO : Add test name');
    @cn = $doc->childNodes;
    # TEST
    is( scalar(@cn) , 1, ' TODO : Add test name');
    # TEST
    ok($cn[0]->isSameNode($node), ' TODO : Add test name');

    $doc->removeChild($node);
    @cn = $doc->childNodes;
    # TEST
    is( scalar(@cn) , 0, ' TODO : Add test name');

    for ( 1..2 ) {
        my $nodeA = $doc->createElement( "x" );
        $doc->setDocumentElement( $nodeA );
    }
    # TEST
    ok(1, ' TODO : Add test name'); # must not segfault here :)

    $doc->setDocumentElement( $node2 );
    @cn = $doc->childNodes;
    # TEST
    is( scalar(@cn) , 1, ' TODO : Add test name');
    # TEST
    ok($cn[0]->isSameNode($node2), ' TODO : Add test name');

    my $node3 = $doc->createElementNS( "http://foo", "bar" );
    # TEST
    ok($node3, ' TODO : Add test name');

    # -> Processing Instructions
    {
        my $pi = $doc->createProcessingInstruction( "foo", "bar" );
        $doc->appendChild( $pi );
        @cn = $doc->childNodes;
        # TEST
        ok( $pi->isSameNode($cn[-1]), ' TODO : Add test name' );
        $pi->setData( 'bar="foo"' );
        # TEST
        is( $pi->textContent, 'bar="foo"', ' TODO : Add test name');
        $pi->setData( foo=>"foo" );
        # TEST
        is( $pi->textContent, 'foo="foo"', ' TODO : Add test name');
    }
}

package Stringify;

use overload q[""] => sub { return '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>'; };

sub new
{
    return bless \(my $x);
}

package main;

{
    # Document Storing
    my $parser = LibXML->new;
    my $doc = $parser->parse_string("<foo>bar</foo>");

    # TEST

    ok( $doc, ' TODO : Add test name' );

    # -> to file handle

    {
        open my $fh, '>', 'example/testrun.xml'
            or die "Cannot open example/testrun.xml for writing - $!.";

        $doc->toFH( $fh );
        $fh->close;
        # TEST
        ok(1, ' TODO : Add test name');
        # now parse the file to check, if succeeded
        my $tdoc = $parser->parse_file( "example/testrun.xml" );
        # TEST
        ok( $tdoc, ' TODO : Add test name' );
        # TEST
        ok( $tdoc->documentElement, ' TODO : Add test name' );
        # TEST
        is( $tdoc->documentElement->nodeName, "foo", ' TODO : Add test name' );
        # TEST
        is( $tdoc->documentElement->textContent, "bar", ' TODO : Add test name' );
        unlink "example/testrun.xml" ;
    }

    # -> to named file
    {
        $doc->toFile( "example/testrun.xml" );
        # TEST
        ok(1, ' TODO : Add test name');
        # now parse the file to check, if succeeded
        my $tdoc = $parser->parse_file( "example/testrun.xml" );
        # TEST
        ok( $tdoc, ' TODO : Add test name' );
        # TEST
        ok( $tdoc->documentElement, ' TODO : Add test name' );
        # TEST
        is( $tdoc->documentElement->nodeName, "foo", ' TODO : Add test name' );
        # TEST
        is( $tdoc->documentElement->textContent, "bar", ' TODO : Add test name' );
        unlink "example/testrun.xml" ;
    }

    # ELEMENT LIKE FUNCTIONS
    {
        my $parser2 = LibXML->new();
        my $string1 = "<A><A><B/></A><A><B/></A></A>";
        my $string2 = '<C:A xmlns:C="xml://D"><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string3 = '<A xmlns="xml://D"><A><B/></A><A><B/></A></A>';
        my $string4 = '<C:A><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string5 = '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>';
        {
            my $doc2 = $parser2->parse_string($string1);
            # TEST
            _count_tag_name($doc2, 'A', 3, q{3 As});
            # TEST
            _count_tag_name($doc2, '*', 5, q{5 elements of all names});

            # TEST
            _count_elements_by_name_ns($doc2, ['*', 'B'], 2,
                '2 Bs of any namespace'
            );

            # TEST
            _count_local_name($doc2, 'A', 3, q{3 A's});

            # TEST
            _count_local_name($doc2, '*', 5, q{5 Sub-elements});
        }
        {
            my $doc2 = $parser2->parse_string($string2);
            # TEST
            _count_tag_name( $doc2, 'C:A', 3, q{C:A count});
            # TEST
            _count_elements_by_name_ns($doc2, [ "xml://D", "A" ], 3,
                q{3 elements of namespace xml://D and A},
            );
            # TEST
            _count_elements_by_name_ns($doc2, ['*', 'A'], 3,
                q{3 Elements A of any namespace}
            );
            # TEST
            _count_local_name($doc2, 'A', 3, q{3 As});
        }
        {
            my $doc2 = $parser2->parse_string($string3);
            # TEST
            _count_elements_by_name_ns($doc2, ["xml://D", "A"], 3,
                q{3 Elements A of any namespace}
            );
            # TEST
            _count_local_name($doc2, 'A', 3, q{3 As});
        }
=begin taken_out
        # This was taken out because the XML uses an undefined namespace.
        # I don't know why this test was introduced in the first place,
        # but it fails now
        #
        # This test fails in this bug report -
        # https://rt.cpan.org/Ticket/Display.html?id=75403
        # -- Shlomi Fish
        {
            $parser2->recover(1);
            local $SIG{'__WARN__'} = sub {
                  print "warning caught: @_\n";
            };
            # my $doc2 = $parser2->parse_string($string4);
            #-TEST
            # _count_local_name( $doc2, 'A', 3, q{3 As});
        }
=end taken_out

=cut
    # TEST:$count=3;
    # Also test that we can parse from scalar references:
    # See RT #64051 ( https://rt.cpan.org/Ticket/Display.html?id=64051 )
    # Also test that we can parse from references to scalars with
    # overloaded strings:
    # See RT #77864 ( https://rt.cpan.org/Public/Bug/Display.html?id=77864 )

        my $obj = Stringify->new;

        foreach my $input ( $string5, (\$string5), $obj )
        {
            my $doc2 = $parser2->parse_string($input);
            # TEST*$count
            _count_tag_name($doc2, 'C:A', 1, q{3 C:As});
            # TEST*$count
            _count_tag_name($doc2, 'A', 3, q{3 As});
            # TEST*$count
            _count_elements_by_name_ns($doc2, ["*", "A"], 4,
                q{4 Elements of A of any namespace}
            );
            # TEST*$count
            _count_elements_by_name_ns($doc2, ['*', '*'], 5,
                q{4 Elements of any namespace},
            );
            # TEST*$count
            _count_elements_by_name_ns( $doc2, ["xml://D", "*" ], 2,
                q{2 elements of any name in D}
            );

            my $A = $doc2->getDocumentElement;
            # TEST*$count
            _count_children_by_name($A, 'A', 1, q{1 A});
            # TEST*$count
            _count_children_by_name($A, 'C:A', 1, q{C:A});
            # TEST*$count
            _count_children_by_name($A, 'C:B', 0, q{No C:B children});
            # TEST*$count
            _count_children_by_name($A, "*", 2, q{2 Childern in $A in total});
            # TEST*$count
            _count_children_by_name_ns($A, ['*', 'A'], 2,
                q{2 As of any namespace});
            # TEST*$count
            _count_children_by_name_ns($A, [ "xml://D", "*" ], 1,
                q{1 Child of D},
            );
            # TEST*$count
            _count_children_by_name_ns($A, [ "*", "*" ], 2,
                q{2 Children in total},
            );
            # TEST*$count
            _count_children_by_local_name($A, 'A', 2, q{2 As});
        }
    }
}

{
    # Bug fixes (to be used with valgrind)
    {
       my $doc=LibXML->createDocument(); # create a doc
       my $x=$doc->createPI(foo=>"bar");      # create a PI
       undef $doc;                            # should not free
       undef $x;                              # free the PI
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML->createDocument(); # create a doc
       my $x=$doc->createAttribute(foo=>"bar"); # create an attribute
       undef $doc;                            # should not free
       undef $x;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML->createDocument(); # create a doc
       my $x=$doc->createAttributeNS(undef,foo=>"bar"); # create an attribute
       undef $doc;                            # should not free
       undef $x;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML->new->parse_string('<foo xmlns:x="http://foo.bar"/>');
       my $x=$doc->createAttributeNS('http://foo.bar','x:foo'=>"bar"); # create an attribute
       undef $doc;                            # should not free
       undef $x;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
      # rt.cpan.org #30610
      # valgrind this
      my $object=LibXML::Element->new( 'object' );
      my $xml = qq(<?xml version="1.0" encoding="UTF-8"?>\n<lom/>);
      my $lom_doc=LibXML->new->parse_string($xml);
      my $lom_root=$lom_doc->getDocumentElement();
      $object->appendChild( $lom_root );
      # TEST
      ok(!defined($object->firstChild->ownerDocument), ' TODO : Add test name');
    }
}


{
  my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<test/>
};
  my $out = q{<?xml version="1.0"?>
<test/>
};
  my $dom = LibXML->new->parse_string($xml);
  # TEST
  is($dom->getEncoding, "UTF-8", ' TODO : Add test name');
  $dom->setEncoding();
  # TEST
  is($dom->getEncoding, undef, ' TODO : Add test name');
  # TEST
  is($dom->toString, $out, ' TODO : Add test name');
}

# the following tests were added for #33810
SKIP:
{
    if (! eval { require Encode; })
    {
        skip "Encoding related tests require Encode", (3*8);
    }
    # TEST:$num_encs=3;
    # The count.
    # TEST:$c=0;
    for my $enc (qw(UTF-16 UTF-16LE UTF-16BE)) {
        my $xml = Encode::encode($enc,qq{<?xml version="1.0" encoding="$enc"?>
            <test foo="bar"/>
            });
        my $dom = LibXML->new->parse_string($xml);
        # TEST:$c++;
        is($dom->getEncoding,$enc, ' TODO : Add test name');
        # TEST:$c++;
        is($dom->actualEncoding,$enc, ' TODO : Add test name');
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute('foo'),'bar', ' TODO : Add test name');
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute(Encode::encode('UTF-16','foo')), 'bar', ' TODO : Add test name');
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute(Encode::encode($enc,'foo')), 'bar', ' TODO : Add test name');
        my $exp_enc = $enc eq 'UTF-16' ? 'UTF-16LE' : $enc;
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute('foo',1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute(Encode::encode('UTF-16','foo'),1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
        # TEST:$c++;
        is($dom->getDocumentElement->getAttribute(Encode::encode($enc,'foo'),1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
    }
    # TEST*$num_encs*$c
}

=end POD
