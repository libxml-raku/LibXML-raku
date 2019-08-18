use v6;
use Test;
##
# this test checks the DOM Document interface of XML::LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

# since all tests are run on a preparsed

plan 171;

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
     is($node.nodeType, +XML_ELEMENT_NODE, "$blurb - node is an element node");
     is($node.nodeName, $name, "$blurb - node has the right name.");
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

sub _multi_arg_generic_count(LibXML::Node $node, Str $method, List $params)
{
    my (List $meth_params, UInt $want_count, Str $blurb) = @$params;
    my @elems = $node."$method"( |$meth_params );
    return is(+(@elems), $want_count, $blurb);
}

sub _generic_count(LibXML::Node $node, Str $method, List $params)
{
    my (Str $name, UInt $want_count, Str $blurb) = @$params;

    return _multi_arg_generic_count(
        $node, $method, [[$name], $want_count, $blurb, ],
    );
}

sub _count_local_name(LibXML::Document $doc, *@args)
{
    return _generic_count($doc, 'getElementsByLocalName', @args);
}

sub _count_tag_name(LibXML::Node $node, *@args)
{
    return _generic_count($node, 'getElementsByTagName', @args);
}

sub _count_children_by_local_name(LibXML::Node $node, *@args)
{
    return _generic_count($node, 'getChildrenByLocalName', @args);
}

sub _count_children_by_name(LibXML::Node $node, *@args)
{
    return _generic_count($node, 'getChildrenByTagName', @args);
}

sub _count_elements_by_name_ns(LibXML::Node $node, List $ns_and_name, UInt $want_count, Str $blurb)
{
    return _multi_arg_generic_count($node, 'getElementsByTagNameNS',
        [$ns_and_name, $want_count, $blurb]
    );
}

sub _count_children_by_name_ns(LibXML::Node $node, List $ns_and_name, UInt $want_count, Str $blurb)
{
    return _multi_arg_generic_count($node, 'getChildrenByTagNameNS',
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

    $doc.encoding = "iso-8859-1";
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

    my $doc2 = LibXML::Document.createDocument(:version<1.1>, :enc<iso-8859-2>);
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
        is($node.nodeType, +XML_DOCUMENT_FRAG_NODE, 'document fragment type');
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
        is $node.native.nsDef, 'xmlns:foo="http://kungfoo"', 'Node namespace';
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
        need LibXML::CDATA;
        my LibXML::CDATA:D $node = $doc.createCDATASection( "foo" );
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
        is($attr, 'bar', 'attr Str');
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
        my $attr;
        lives-ok {
            $attr = $doc.createAttributeNS("http://kungfoo", "kung:foo","bar");
        }, '$doc.createAttributeNS without root element - dies';

        # TEST
        ok($attr, '$doc.createAttributeNS');
        # TEST
        is($attr.nodeName, "kung:foo", '$doc.createAttributeNS nodeName');
        # TEST
        is($attr.name,"foo", 'attr ns name' );
        # TEST
        is($attr.value, "bar", 'attr ns value' );

        $attr.value = 'bar&amp;';
        # TEST
        is($attr.value, 'bar&amp;', 'attr ns value updated' );

        my $root = $doc.createElement( "foo" );
        $doc.documentElement = $root;
        $root.addChild($attr);
        is $root, '<foo kung:foo="bar&amp;amp;"/>', 'Can use attribute created before document root';
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
        is($pi.nodeType, +XML_PI_NODE, 'PI nodeType');
        # TEST
        is($pi.nodeName, "foo", 'PI nodeName');
        # TEST
        is($pi.string-value, "bar", 'PI string-value');
        # TEST
        is($pi.content, "bar", 'PI content');
    }

    {
        my $pi = $doc.createProcessingInstruction( "foo" );
        # TEST
        is($pi, '<?foo?>');
        # TEST
        is($pi.nodeType, +XML_PI_NODE, 'PI nodeType');
        # TEST
        is($pi.nodeName, "foo", 'PI nodeName');
        my $data = $pi.content;
        # undef or "" depending on libxml2 version
        # TEST
        ok( is-empty-str($data), 'PI content (empty)' );
        $data = $pi.string-value;
        # TEST
        ok( is-empty-str($data), 'PI string-value (empty)' );
        $pi.nodeValue = 'bar&amp;';
        # TEST
        is($pi.content, 'bar&amp;', 'PI content updated');
        is $pi, '<?foo bar&amp;?>';
    }
}

{
    # Document Manipulation
    # -> Document Elements

    my LibXML::Document:D $doc .= new();
    my LibXML::Element $node = $doc.createElement( "foo" );
    $doc.documentElement = $node;
    my $tn = $doc.documentElement;
    # TEST
    is($tn, '<foo/>', 'set document element');
    # TEST
    ok($node.isSameNode($tn), 'document element preserved');

    my $node2 = $doc.createElement( "bar" );
    dies-ok {
        $doc.appendChild($node2);
    }, 'Append second document root element - dies';

    my @cn = $doc.childNodes;
    # TEST
    is( +@cn, 1, 'Second document root element is isgnored');
    # TEST
    ok(@cn[0].isSameNode($node), 'document element preserved');

    dies-ok {
      $doc.insertBefore($node2, $node);
    }, "Can't insertBefore document root";
    # TEST
    @cn = $doc.childNodes;
    # TEST
    is( +@cn, 1, "Can't insertBefore document root");
    # TEST
    ok(@cn[0].isSameNode($node), 'document element preserved');

    $doc.removeChild($node);
    @cn = $doc.childNodes;
    # TEST
    is( +@cn, 0, 'document removeChild of root element');

    for ( 1..2 ) {
        my $nodeA = $doc.createElement( "x" );
        $doc.documentElement = $nodeA;
    }
    # TEST
    ok(1, 'Replacement of document root element'); # must not segfault here :)

    $doc.documentElement = $node2;
    @cn = $doc.childNodes;
    # TEST
    is( +@cn, 1, 'Replaced root element');
    # TEST
    ok(@cn[0].isSameNode($node2), 'Replaced root element');

    my $node3 = $doc.createElementNS( "http://foo", "bar" );
    # TEST
    is($node3, '<bar xmlns="http://foo"/>', '$doc.createElementNS');

    # . Processing Instructions
    {
        my $pi = $doc.createProcessingInstruction( "foo", "bar" );
        $doc.appendChild( $pi );
        @cn = $doc.childNodes;
        # TEST
        ok( $pi.isSameNode(@cn.tail), 'Append processing instruction to document root' );
        $pi.nodeValue = 'bar="foo"';
        # TEST
        is( $pi.content, 'bar="foo"', 'Appended processing instruction');
        $pi.nodeValue = foo=>"foo";
        # TEST
        todo("check test valid?");
        is( $pi.content, 'foo="foo"', 'Append Pair as processing instruction');
    }
}

{
    need LibXML::Document;
    # Document Storing
    my LibXML:D $parser .= new;
    my LibXML::Document:D $doc = $parser.parse: :string("<foo>bar</foo>");

    # TEST

    is-deeply( $doc.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>', '<foo>bar</foo>'), 'string parse sanity' );

    # . to file handle

    {
        my IO::Handle $io = 'example/testrun.xml'.IO.open(:w);

        $doc.save: :$io;
        $io.close;
        # TEST
        ok(1, ' TODO : Add test name');
        # now parse the file to check, if succeeded
        my $tdoc = $parser.parse: :file( "example/testrun.xml" );
        # TEST
        is-deeply( $tdoc.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>' , '<foo>bar</foo>'), ' TODO : Add test name' );
        # TEST
        is( $tdoc.documentElement, '<foo>bar</foo>', ' TODO : Add test name' );
        # TEST
        is( $tdoc.documentElement.nodeName, "foo", ' TODO : Add test name' );
        # TEST
        is( $tdoc.documentElement.string-value, "bar", ' TODO : Add test name' );
        unlink "example/testrun.xml" ;
    }

    # -> to named file
    {
        $doc.save: :file( "example/testrun.xml" );
        # TEST
        ok(1, ' TODO : Add test name');
        # now parse the file to check, if succeeded
        my $tdoc = $parser.parse: :file( "example/testrun.xml" );
        # TEST
        ok( $tdoc, ' TODO : Add test name' );
        # TEST
        ok( $tdoc.documentElement, ' TODO : Add test name' );
        # TEST
        is( $tdoc.documentElement.nodeName, "foo", ' TODO : Add test name' );
        # TEST
        is( $tdoc.documentElement.string-value, "bar", ' TODO : Add test name' );
        unlink "example/testrun.xml" ;
    }

    # ELEMENT LIKE FUNCTIONS
    {
        my $parser2 = LibXML.new();
        my $string1 = "<A><A><B/></A><A><B/></A></A>";
        my $string2 = '<C:A xmlns:C="xml://D"><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string3 = '<A xmlns="xml://D"><A><B/></A><A><B/></A></A>';
        my $string4 = '<C:A><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string5 = '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>';
        {
            my $doc2 = $parser2.parse: :string($string1);
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
            my $doc2 = $parser2.parse: :string($string2);
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
            my $doc2 = $parser2.parse: :string($string3);
            # TEST
            _count_elements_by_name_ns($doc2, ["xml://D", "A"], 3,
                q{3 Elements A of any namespace}
            );
            # TEST
            _count_local_name($doc2, 'A', 3, q{3 As});
        }

        {
            my $doc2 = $parser2.parse: :string($string5);
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
            my $A = $doc2.documentElement;
            # TEST*$count
            _count_children_by_name($A, 'A', 1, q{1 A});
            # TEST*$count
            _count_children_by_name($A, 'C:A', 1, q{C:A});
            # TEST*$count
            _count_children_by_name($A, 'C:B', 0, q{No C:B children});
            # TEST*$count
            _count_children_by_name($A, "*", 2, q{2 Children in $A in total});
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
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createPI('foo'=>"bar");      # create a PI
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the PI
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createAttribute('foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createAttributeNS(Str,'foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
       my $doc=LibXML.new.parse: :string('<foo xmlns:x="http://foo.bar"/>');
       my $x=$doc.createAttributeNS('http://foo.bar','x:foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
       # TEST
       ok(1, ' TODO : Add test name');
    }
    {
      # rt.cpan.org #30610
      # valgrind this
      my $object=LibXML::Element.new( :name<object> );
      my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>\n<lom/>};
      my $lom_doc=LibXML.new.parse: :string($xml);
      my $lom_root=$lom_doc.getDocumentElement();
      $object.appendChild( $lom_root );
      # TEST
      ok(!defined($object.firstChild.ownerDocument), ' TODO : Add test name');
    }
}

{
  my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<test/>
};
  my $dom = LibXML.new.parse: :string($xml);
  # TEST
  is($dom.encoding, "UTF-8", 'Document encoding');
  $dom.encoding = Nil;
  # TEST
  is-deeply($dom.encoding, Str, 'Document encoding cleared');
  # TEST
  is($dom.Str, $xml, ' TODO : Add test name');
}

{
    my $name = "Heydər Əliyev";

    for ('UTF-16LE', 'UTF-16BE', 'UTF-16', 'ISO-8859-1') -> $enc {
        my $name-enc = $enc eq 'ISO-8859-1'
            ?? $name.ords.map({32 <= $_ <= 127 ?? .chr !! sprintf("&#%d;", $_)}).join
            !! $name;
        my $xml-header = '<?xml version="1.0" encoding="%s"?>'.sprintf: $enc;
        my $xml-root-pretty = '<test foo="%s">%s</test>'.sprintf($name, $name);
        my $xml-root = '<test foo="%s">%s</test>'.sprintf($name-enc, $name-enc);
        my $string = ($xml-header, $xml-root, '').join: "\n";

        my Blob $buf = $string.encode: $enc;
        my $dom = LibXML.new.parse: :$buf;
        
        # TEST:$c++;
        is $dom.encoding, $enc, "$enc encoding";
        my $root = $dom.getDocumentElement;
        is $root.getAttribute('foo'), $name, "$enc encoding getAttribute";
        is $root.firstChild.nodeValue, $name, 'node value';
        # TEST:$c++;
        is-deeply $dom.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>', $xml-root-pretty), '.Str method';
        # peek at the first few bytes
        my $dom-blob = $dom.Blob;
        my $start-bytes = $dom-blob.subbuf(0, 4).List;
        my $expected-start-bytes = %(
            'UTF-16LE'   => (60,0,63,0),
            'UTF-16BE'   => (0,60,0,63),
            'UTF-16'     => ((255,254,60,0)|(254,255,0,60)), # BOM marker, big or little endian
            'ISO-8859-1' => (60,63,120,109),
        ){$enc};
        ok $start-bytes ~~ $expected-start-bytes, "Blob $enc start bytes"
           or diag "unexpect start bytes in $enc Blob: $start-bytes";
        is-deeply $dom-blob.decode($enc).lines, ($xml-header, $xml-root), "$enc blob round-trip";
        # TEST:$c++;
    }
    # TEST*$num_encs*$c
}

subtest 'compress' => {
    plan 5;
    use File::Temp;
    my LibXML::Document:D $doc = LibXML.load: :file( "example/test.xml" );
    is-deeply $doc.input-compressed , False, 'input-compression of uncompressed document';
    if LibXML.have-compression {
        lives-ok { $doc = LibXML.load: :file<test/compression/test.xml.gz> }, 'load compressed document';
        is-deeply $doc.input-compressed, True, 'document input-compression';
        $doc.compression = 5;
        is $doc.compression, 5, 'set document compression';
        my (Str:D $file) = tempfile();
        my $n = $doc.write: :$file;
        $doc = LibXML.load: :$file;
        is-deeply $doc.input-compressed , True, 'compression of written document';
    }
    else {
        skip "LibXML compression is not available for compression tests", 4;
    }
}
