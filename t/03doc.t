use v6;
use Test;

# this test checks the DOM Document interface of LibXML
# it relies on the success of t/01basic.t and t/02parse.t

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

plan 9;

use LibXML;
use LibXML::Document;
use LibXML::Element;
use LibXML::Enums;

sub is-empty-str(Str $s)
{
    ! $s.so;
}

sub _check_element_node(LibXML::Node $node, Str $name, Str $blurb)
{
     ok $node, "$blurb - node was initialised";
     is $node.nodeType, +XML_ELEMENT_NODE, "$blurb - node is an element node";
     is $node.nodeName, $name, "$blurb - node has the right name.";
}


sub _check_created_element(LibXML::Document $doc, Str $given-name, Str $name, Str $blurb)
{
    _check_element_node(
        $doc.createElement($given-name),
        $name,
        $blurb
    );
}

sub _multi_arg_generic_count(LibXML::Node $node, Str $method, @ (List $meth_params, UInt $want_count, Str $blurb))
{
    my @elems = $node."$method"( |$meth_params );
    is +(@elems), $want_count, $blurb;
}

sub _generic_count(LibXML::Node $node, Str $method, @ (Str $name, UInt $want_count, Str $blurb))
{
    _multi_arg_generic_count(
        $node, $method, [[$name], $want_count, $blurb, ],
    );
}

sub _count_local_name(LibXML::Document $doc, *@args)
{
    _generic_count($doc, 'getElementsByLocalName', @args);
}

sub _count_tag_name(LibXML::Node $node, *@args)
{
    _generic_count($node, 'getElementsByTagName', @args);
}

sub _count_children_by_local_name(LibXML::Node $node, *@args)
{
    _generic_count($node, 'getChildrenByLocalName', @args);
}

sub _count_children_by_name(LibXML::Node $node, *@args)
{
    _generic_count($node, 'getChildrenByTagName', @args);
}

sub _count_elements_by_name_ns(LibXML::Node $node, List $ns_and_name, UInt $want_count, Str $blurb)
{
    _multi_arg_generic_count($node, 'getElementsByTagNameNS',
        [$ns_and_name, $want_count, $blurb]
    );
}

sub _count_children_by_name_ns(LibXML::Node $node, List $ns_and_name, UInt $want_count, Str $blurb)
{
    _multi_arg_generic_count($node, 'getChildrenByTagNameNS',
        [$ns_and_name, $want_count, $blurb]
    );
}

subtest 'document attributes', {
    my LibXML::Document $doc .= createDocument();
    ok $doc.defined, 'document creation';

    ok ! defined($doc.encoding), 'doc.encoding';
    is $doc.version,  "1.0", 'doc.version';
    is $doc.standalone, -1, 'doc.standalone';  # is the value we get for undefined,
                                 # actually the same as 0 but just not set.
    ok !defined($doc.URI), 'doc.URI';  # should be set by default.
    is $doc.compression, -1, 'doc.compression'; # -1 indicates NO compression at all!
                                 # while 0 indicates just no zip compression
                                 # (big difference huh?)

    $doc.encoding = "iso-8859-1";
    is $doc.encoding, "iso-8859-1", 'Encoding was set.';

    $doc.version = "12.5";
    is $doc.version, "12.5", 'Version was set.';

    $doc.standalone = 1;
    is $doc.standalone, 1, 'Standalone was set.';

    $doc.baseURI = "localhost/here.xml";
    is $doc.URI, "localhost/here.xml", 'URI is set.';

    if $*DISTRO.is-win {
        skip 'proper encoding support', 3;
    }
    else {
        my $doc2 = LibXML::Document.createDocument(:version<1.1>, :enc<iso-8859-2>);
        is $doc2.encoding, "iso-8859-2", 'doc2 encoding was set.';
        is $doc2.version,  "1.1", 'doc2 version was set.';
        is $doc2.standalone,  -1, 'doc2 standalone';
    }
}

subtest 'creating elements', {
    my LibXML::Document $doc .= new();
    subtest 'document fragments', {
        my $node = $doc.createDocumentFragment();
        ok $node.defined, '$doc.createDocumentFragment';
        is $node.nodeType, +XML_DOCUMENT_FRAG_NODE, 'document fragment type';
    }

    _check_created_element($doc, 'foo', 'foo', 'Simple Element');

    subtest 'document with encoding', {
        my LibXML::Document $encdoc .= new;
        $encdoc.encoding = "iso-8859-1";

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

        _check_created_element(
            $encdoc, %node_def<Name>, 'object',
            'Encdoc element creation based on node_def->{name}',
        );
    }

    subtest 'namespaced elements', {
        my $node = $doc.createElementNS( "http://kungfoo", "foo:bar" );
        is $node.raw.nsDef, 'xmlns:foo="http://kungfoo"', 'Node namespace';
        is $node, '<foo:bar xmlns:foo="http://kungfoo"/>', '$doc.createElement';
        is $node.nodeType, +XML_ELEMENT_NODE, '$node.nodeType';
        is $node.nodeName, "foo:bar", '$node.nodeName';
        is $node.prefix, "foo", '$node.prefix';
        is $node.localname, "bar", '$node.localname';
        is $node.namespaceURI, "http://kungfoo", '$node.namespaceURI';
    }

    subtest 'bad element creation', {
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createElement( $name );};
        }

    }

    subtest 'text nodes', {
        need LibXML::Text;
        my LibXML::Text:D $node = $doc.createTextNode( "foo" );
        is $node, 'foo', 'text Str';
        is $node.nodeType, +XML_TEXT_NODE, 'text node type';
        is $node.nodeValue, "foo", 'text node value';
    }

    subtest 'comments', {
        need LibXML::Comment;
        my LibXML::Comment:D $node = $doc.createComment( "foo" );
        is $node, '<!--foo-->', 'comment Str';
        is $node.nodeType, +XML_COMMENT_NODE, 'comment node type';
        is $node.nodeValue, "foo", 'comment node value';
        is $node.Str, "<!--foo-->", 'Comment node string';
    }

    subtest 'cdata', {
        need LibXML::CDATA;
        my LibXML::CDATA:D $node = $doc.createCDATASection( "foo" );
        is $node.nodeType, +XML_CDATA_SECTION_NODE, 'CDATA node type';
        is $node.nodeValue, "foo", 'CDATA node value';
        is $node.Str, "<![CDATA[foo]]>", 'CDATA node string';
    }

    subtest 'attributes', {
        need LibXML::Attr;
        need LibXML::Text;
        my LibXML::Attr:D $attr = $doc.createAttribute("foo", "bar");
        is $attr, 'bar', 'attr Str';
        is $attr.nodeType, +XML_ATTRIBUTE_NODE, 'attr nodeType';
        is $attr.name, "foo", 'attr name';
        is $attr.value, "bar", 'attr value';
        is-deeply $attr.hasChildNodes, False, 'att hasChildNodes';
        my  LibXML::Text:D $content = $attr.firstChild;
        is  $content, 'bar', 'attr content Str';
        is  $content.nodeType, +XML_TEXT_NODE, 'attribute content is a text node';
    }

    subtest 'bad attributes', {
        # bad attribute creation
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createAttribute( $name, "bar" );}, "badd att name: $name";
        }

    }

    subtest 'element attributes', {
      need LibXML::Element;
      need LibXML::Attr;
      my LibXML::Element:D $elem = $doc.createElement('foo');
      my LibXML::Attr:D $attr = $doc.createAttribute('attr', 'e & f');
      $elem.setAttributeNode($attr);
      is($elem, '<foo attr="e &amp; f"/>', 'Elem with attribute added');
      $elem.removeAttribute('attr');
      $attr = $doc.createAttribute('attr2' => 'a & b');
      $elem.addChild($attr);
      is $elem, '<foo attr2="a &amp; b"/>', 'Elem replace attributes';
    }

    subtest 'attributes with namespaces', {
        my $attr;
        lives-ok {
            $attr = $doc.createAttributeNS("http://kungfoo", "kung:foo","bar");
        }, '$doc.createAttributeNS without root element - dies';

        ok $attr, '$doc.createAttributeNS';
        is $attr.nodeName, "kung:foo", '$doc.createAttributeNS nodeName';
        is $attr.name,"foo", 'attr ns name';
        is $attr.value, "bar", 'attr ns value';

        $attr.value = 'bar&amp;';
        is $attr.value, 'bar&amp;', 'attr ns value updated';

        my $root = $doc.createElement( "foo" );
        $doc.documentElement = $root;
        $root.addChild($attr);
        is $root, '<foo kung:foo="bar&amp;amp;"/>', 'Can use attribute created before document root';
    }

    subtest 'good attribute creation', {
        my @goodnames = ( "foo", "bar:baz");

        for @goodnames -> $name {
            lives-ok {$doc.createAttributeNS( Str, $name, "bar" );}, 'createAttributeNS with good name';
        }

    }

    subtest 'bad attribute creation', {
        # bad attribute creation
        my @badnames = ( ";", "&", "<><", "/", "1A");

        for @badnames -> $name {
            dies-ok {$doc.createAttributeNS( Str, $name, "bar" );}, 'createAttributeNS with bad name';
        }

    }

    subtest 'create PI, two arguments', {
        need LibXML::PI;
        my LibXML::PI:D $pi = $doc.createProcessingInstruction( "foo", "bar" );
        is $pi, '<?foo bar?>';
        is $pi.nodeType, +XML_PI_NODE, 'PI nodeType';
        is $pi.nodeName, "foo", 'PI nodeName';
        is $pi.target, "foo", 'PI target';
        is $pi.ast-key, "?foo", 'PI ast-key';
        is $pi.xpath-key, "processing-instruction()", 'PI xpath-key';
        is $pi.string-value, "bar", 'PI string-value';
        is $pi.content, "bar", 'PI content';
        is $pi.content, "bar", 'PI data';
    }

    subtest 'create PI, single argument', {
        my $pi = $doc.createProcessingInstruction( "foo" );
        is $pi, '<?foo?>';
        is $pi.nodeType, +XML_PI_NODE, 'PI nodeType';
        is $pi.nodeName, "foo", 'PI nodeName';
        my $data = $pi.content;
        # undef or "" depending on libxml2 version
        ok is-empty-str($data), 'PI content (empty)';
        $data = $pi.string-value;
        ok is-empty-str($data), 'PI string-value (empty)';
        $pi.nodeValue = 'bar&amp;';
        is $pi.content, 'bar&amp;', 'PI content updated';
        is $pi, '<?foo bar&amp;?>';
    }
}

subtest 'document manipulation', {
    # Document Manipulation
    # -> Document Elements

    my LibXML::Document $doc .= new();
    my LibXML::Element $node = $doc.createElement( "foo" );
    $doc.documentElement = $node;
    my $tn = $doc.documentElement;
    is($tn, '<foo/>', 'set document element');
    ok($node.isSameNode($tn), 'document element preserved');

    my $node2 = $doc.createElement( "bar" );
    dies-ok {
        $doc.appendChild($node2);
    }, 'Append second document root element - dies';

    my @cn = $doc.childNodes;
    is( +@cn, 1, 'Second document root element is isgnored');
    ok(@cn[0].isSameNode($node), 'document element preserved');

    dies-ok {
      $doc.insertBefore($node2, $node);
    }, "Can't insertBefore document root";
    @cn = $doc.childNodes;
    is( +@cn, 1, "Can't insertBefore document root");
    ok(@cn[0].isSameNode($node), 'document element preserved');

    $doc.removeChild($node);
    @cn = $doc.childNodes;
    is( +@cn, 0, 'document removeChild of root element');

    $doc.addNewChild( Str, 'baz' );
    is $doc.childNodes, '<baz/>', 'addNewChild';
    $doc.removeChild($doc[0]);
    is $doc.childNodes, '', 'addNewChild/removeChild';
    
    for 1..2 {
        my $nodeA = $doc.createElement( "x" );
        $doc.documentElement = $nodeA;
    }
    pass('Replacement of document root element');

    $doc.documentElement = $node2;
    @cn = $doc.childNodes;
    is +@cn, 1, 'Replaced root element';
    ok @cn[0].isSameNode($node2), 'Replaced root element';

    my $node3 = $doc.createElementNS( "http://foo", "bar" );
    is($node3, '<bar xmlns="http://foo"/>', '$doc.createElementNS');

    subtest "processing instructions", {
        my $pi = $doc.createProcessingInstruction( "foo", "bar" );
        $doc.appendChild( $pi );
        @cn = $doc.childNodes;
        ok $pi.isSameNode(@cn.tail), 'Append processing instruction to document root';
        $pi.nodeValue = 'bar="foo"';
        is $pi.content, 'bar="foo"', 'Appended processing instruction';
        $pi.nodeValue = foo=>"foo";
        todo "check test valid?";
        is $pi.content, 'foo="foo"', 'Append Pair as processing instruction';
    }
}

subtest 'document storing', {
    need LibXML::Document;

    my LibXML $parser .= new;
    my LibXML::Document $doc = $parser.parse: :string("<foo>bar</foo>");

    is-deeply( $doc.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>', '<foo>bar</foo>'), 'string parse sanity' );


    subtest 'to file handle', {
        my IO::Handle $io = 'samples/testrun.xml'.IO.open(:w);

        lives-ok {
            $doc.save: :$io;
            $io.close;
        }

        # now parse the file to check, if succeeded
        my $tdoc = $parser.parse: :file( "samples/testrun.xml" );
        is-deeply $tdoc.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>' , '<foo>bar</foo>');
        is $tdoc.documentElement, '<foo>bar</foo>';
        is $tdoc.documentElement.nodeName, "foo";
        is $tdoc.documentElement.string-value, "bar";
        unlink "samples/testrun.xml" ;
    }

    subtest 'to named file', {
        $doc.save: :file( "samples/testrun.xml" );
        pass(' TODO : Add test name');
        # now parse the file to check, if succeeded
        my $tdoc = $parser.parse: :file( "samples/testrun.xml" );
        ok( $tdoc, ' TODO : Add test name' );
        ok $tdoc.documentElement;
        is $tdoc.documentElement.nodeName, "foo";
        is $tdoc.documentElement.string-value, "bar";
        unlink "samples/testrun.xml" ;
    }

    subtest 'element like functions', {
        my LibXML $parser2 .= new();
        my $string1 = "<A><A><B/></A><A><B/></A></A>";
        my $string2 = '<C:A xmlns:C="xml://D"><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string3 = '<A xmlns="xml://D"><A><B/></A><A><B/></A></A>';
        my $string4 = '<C:A><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        my $string5 = '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>';
        {
            my $doc2 = $parser2.parse: :string($string1);
            _count_tag_name($doc2, 'A', 3, q{3 As});
            _count_tag_name($doc2, '*', 5, q{5 elements of all names});

            _count_elements_by_name_ns($doc2, ['*', 'B'], 2,
                '2 Bs of any namespace'
            );

            _count_local_name($doc2, 'A', 3, q{3 A's});

            _count_local_name($doc2, '*', 5, q{5 Sub-elements});
        }

        {
            my $doc2 = $parser2.parse: :string($string2);
            _count_tag_name( $doc2, 'C:A', 3, q{C:A count});
            _count_elements_by_name_ns($doc2, [ "xml://D", "A" ], 3,
                q{3 elements of namespace xml://D and A},
            );
            _count_elements_by_name_ns($doc2, ['*', 'A'], 3,
                q{3 Elements A of any namespace}
            );
            _count_local_name($doc2, 'A', 3, q{3 As});
        }
        {
            my $doc2 = $parser2.parse: :string($string3);
            _count_elements_by_name_ns($doc2, ["xml://D", "A"], 3,
                q{3 Elements A of any namespace}
            );
            _count_local_name($doc2, 'A', 3, q{3 As});
        }

        {
            my $doc2 = $parser2.parse: :string($string5);
            _count_tag_name($doc2, 'C:A', 1, q{3 C:As});
            _count_tag_name($doc2, 'A', 3, q{3 As});
            _count_elements_by_name_ns($doc2, ["*", "A"], 4,
                q{4 Elements of A of any namespace}
            );
            _count_elements_by_name_ns($doc2, ['*', '*'], 5,
                q{4 Elements of any namespace},
            );
            _count_elements_by_name_ns( $doc2, ["xml://D", "*" ], 2,
                q{2 elements of any name in D}
            );
            my $A = $doc2.documentElement;
            _count_children_by_name($A, 'A', 1, q{1 A});
            _count_children_by_name($A, 'C:A', 1, q{C:A});
            _count_children_by_name($A, 'C:B', 0, q{No C:B children});
            _count_children_by_name($A, "*", 2, q{2 Children in $A in total});
            _count_children_by_name_ns($A, ['*', 'A'], 2,
                q{2 As of any namespace});
            _count_children_by_name_ns($A, [ "xml://D", "*" ], 1,
                q{1 Child of D},
            );
            _count_children_by_name_ns($A, [ "*", "*" ], 2,
                q{2 Children in total},
            );
            _count_children_by_local_name($A, 'A', 2, q{2 As});
        }
    }
}

subtest 'Nil-ing nodes', {
    lives-ok {
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createPI('foo'=>"bar");      # create a PI
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the PI
    }
    lives-ok {
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createAttribute('foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
    }
    lives-ok {
       my $doc=LibXML.createDocument(); # create a doc
       my $x=$doc.createAttributeNS(Str,'foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
    }
    lives-ok {
       my $doc=LibXML.parse: :string('<foo xmlns:x="http://foo.bar"/>');
       my $x=$doc.createAttributeNS('http://foo.bar','x:foo'=>"bar"); # create an attribute
       $doc = Nil;                            # should not free
       $x = Nil;                              # free the attribute
    }
    do {
      my $xml = qq{<?xml version="1.0" encoding="UTF-8"?>\n<lom/>};
      my $lom_doc = LibXML.parse: :string($xml);
      my LibXML::Element $object = $lom_doc.create(LibXML::Element, :name<object> );
      my $lom_root = $lom_doc.getDocumentElement();
      $object.appendChild( $lom_root );
      ok !defined($object.firstChild.ownerDocument);
    }
}

subtest 'Nil-ing encoding', {
  my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
<test/>
};
  my $dom = LibXML.parse: :string($xml);
  is($dom.encoding, "UTF-8", 'Document encoding');
  $dom.encoding = Nil;
  todo "unreliable on Rakudo <= 2019.07"
      unless $*PERL.compiler.version > v2019.07;
  is-deeply($dom.encoding, Str, 'Document encoding cleared');
  is $dom.Str, $xml;
}

subtest 'various encodings', {
    my $name = "Heydər Əliyev";

    for 'UTF-16LE', 'UTF-16BE', 'UTF-16', 'ISO-8859-1' -> $enc {
        my $name-enc = $enc eq 'ISO-8859-1'
            ?? $name.ords.map({32 <= $_ <= 127 ?? .chr !! sprintf("&#%d;", $_)}).join
            !! $name;
        my $xml-header = '<?xml version="1.0" encoding="%s"?>'.sprintf: $enc;
        my $xml-root-pretty = '<test foo="%s">%s</test>'.sprintf($name, $name);
        my $xml-root = '<test foo="%s">%s</test>'.sprintf($name-enc, $name-enc);
        my $string = ($xml-header, $xml-root, '').join: "\n";

        my Blob $buf = $string.encode: $enc;
        my $dom = LibXML.parse: :$buf;
        
        is $dom.encoding, $enc, "$enc encoding";
        my $root = $dom.getDocumentElement;
        is $root.getAttribute('foo'), $name, "$enc encoding getAttribute";
        is $root.firstChild.nodeValue, $name, "$enc node value";
        is-deeply $dom.Str.lines, ('<?xml version="1.0" encoding="UTF-8"?>', $xml-root-pretty), "$enc .Str method";
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
    }
}

subtest 'compress' => {
    plan 5;
    use File::Temp;
    my LibXML::Document:D $doc .= parse: :file( "samples/test.xml" );
    todo '$doc.input-compressed is unreliable in libxml <= v2.09.01'
        if LibXML.version <= v2.09.01;
    todo "unreliable on Windows" if $*DISTRO.is-win;
    is-deeply $doc.input-compressed , False, 'input-compression of uncompressed document';
    if LibXML.have-compression {
        lives-ok { $doc = LibXML.parse: :file<test/compression/test.xml.gz> }, 'load compressed document';
        is-deeply $doc.input-compressed, True, 'document input-compression';
        $doc.compression = 5;
        is $doc.compression, 5, 'set document compression';
        my (Str:D $file) = tempfile();
        my $n = $doc.write: :$file;
        $doc = LibXML.parse: :$file;
        is-deeply $doc.input-compressed , True, 'compression of written document';
    }
    else {
        skip "LibXML compression is not available for compression tests", 4;
    }
}

sub check-standalone($code is raw, Str $string, Bool $expected) {
    use LibXML::Document;
    my LibXML::Document $doc .= new: :version('1.0'), :enc('UTF-8');
    $doc.setStandalone($code);
    my LibXML::Element $root = $doc.createElement('Types');
    $root.setNamespace('http://schemas.openxmlformats.org/package/2006/content-types');
    $doc.setDocumentElement($root);
    is $doc.Str.lines.head.contains($string), $expected, "standalone=$code; declaration {$expected ?? 'contains' !! 'lacks'} $string";
}

subtest 'issue#37 - standalone mixup' => {
    use LibXML::Document;
    plan 3;
    check-standalone(LibXML::Document::XmlStandaloneYes, 'standalone="yes"', True);
    check-standalone(LibXML::Document::XmlStandaloneNo, 'standalone="no"', True);
    check-standalone(LibXML::Document::XmlStandaloneMu, 'standalone', False);
    
}
