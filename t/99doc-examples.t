# test synopsis and code samples in POD Documentation
use v6;
use Test;
use LibXML::Attr;
use LibXML::Config;

plan 18;

subtest 'LibXML::Attr' => {
    plan 5;
    my $name = "test";
    my $value = "Value";
    my LibXML::Attr $attr .= new(:$name, :$value);
    my Str:D $string = $attr.getValue();
    is $string, $value, '.getValue';
    $string = $attr.value;
    is $string, $value, '.getValue';
    $attr.setValue( '' );
    is $attr.value, '', '.setValue';
    $attr.value = $string;
    is $attr.value, $string, '.value';
    my LibXML::Node $node = $attr.getOwnerElement();
    my $nsUri = 'http://test.org';
    my $prefix = 'test';
    $attr.setNamespace($nsUri, $prefix);
    my Bool $is-id = $attr.isId;
    $string = $attr.serializeContent;
    is $string, $value;
};

subtest 'LibXML::Attr::Map' => {
    plan 6;
    use LibXML::Attr::Map;
    use LibXML::Document;
    use LibXML::Element;
    my LibXML::Document $doc .= parse('<foo att1="AAA" att2="BBB"/>');
    my LibXML::Element $node = $doc.root;
    my LibXML::Attr::Map $atts = $node.attributes;

    is-deeply ($atts.keys.sort), ('att1', 'att2');
    is $atts<att1>.Str, 'AAA';
    is $atts<att1>.gist, 'att1="AAA"';
    $atts<att2>:delete;
    $atts<att3> = "CCC";
    is $node.Str, '<foo att1="AAA" att3="CCC"/>';

    my LibXML::Attr $style .= create: :from($node), :name<style>, :value('fontweight: bold');
    $atts.setNamedItem($style);
    $style = $atts.getNamedItem('style');
    like $node.Str, rx:s/ 'style="fontweight: bold"' /;
    $atts.removeNamedItem('style');
    unlike $node.Str, rx:s/ 'style="fontweight: bold"' /;
}

subtest 'LibXML::Comment' => {
    plan 1;
    use LibXML::Comment;
    my LibXML::Comment $node .= new: :content("This is a comment");
    is $node.content, "This is a comment";
}

subtest 'LibXML::CDATA' => {
    plan 1;
    use LibXML::CDATA;
    my LibXML::CDATA $node .= new: :content("This is cdata");
    is $node.content, "This is cdata";
}

subtest 'LibXML::Document' => {
    plan 8;
    use LibXML;
    my $version = '1.0';
    my $enc = 'UTF-8';
    my $numvalue = 1;
    my $ziplevel = 5;
    my Bool $format = True;
    my LibXML::Document $doc .= parse("samples/dtd.xml", :dtd);
    my $rootnode = $doc.documentElement;
    my Bool $comments = True;
    my $nodename = 'test';
    my $namespaceURI = "http://kungfoo";
    my $content_text = 'Text node';
    my $value = 'Node value';
    my $comment_text = 'This is a comment';
    my $cdata_content = 'This is cdata';
    my $public = "-//W3C//DTD XHTML 1.0 Transitional//EN";
    my $system = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";
    my $name = 'att_name';
    my $tagname = 'doc';

    my LibXML::Document $dom  .= new: :$version, :$enc;
    my LibXML::Document $dom2 .= createDocument( $version, $enc );

    my Str $URI = $doc.URI();
    is $URI, "samples/dtd.xml";
    $doc.setURI($URI);
    $doc.URI = $URI;
    my $strEncoding = $doc.encoding();
    $strEncoding = $doc.actualEncoding();
    $doc.setEncoding($enc);
    $doc.encoding = $enc;
    my Version $v = $doc.version();
    is $v, v1.0;
    $doc.standalone;
    $doc.setStandalone($numvalue);
    $doc.standalone = $numvalue;
    my $compression = $doc.compression;
    $doc.setCompression($ziplevel);
    $doc.compression = $ziplevel;
    my $docstring = $doc.Str(:$format);
    like $docstring, /'<?xml '/;
    my $c14nstr = $doc.Str(:C14N, :$comments);
    my $ec14nstr = $doc.Str(:C14N, :exclusive, :$comments);
    my $str = $doc.serialize(:$format);
    like $docstring, /'<?xml '/;
    # tested in 03doc.t
    ## $doc.save: :$io;
    $str = $doc.Str: :html;
    like $str, /'<!DOCTYPE doc'/;
    $str = $doc.serialize-html();
    like $str, /'<!DOCTYPE doc'/;
    my $bool = $doc.is-valid();
    $doc.validate();
    my $root = $doc.documentElement();
    $doc.setDocumentElement( $root );
    $doc.documentElement = $root;
    my $node = $dom.createElement( $nodename );
    my $element = $dom.createElementNS( $namespaceURI, $nodename );
    my $text = $dom.createTextNode( $content_text );
    my $comment = $dom.createComment( $comment_text );
    my $attrnode = $doc.createAttribute($name);
    $attrnode = $doc.createAttribute($name ,$value);
    $attrnode = $doc.createAttributeNS( $namespaceURI, $name );
    $attrnode = $doc.createAttributeNS( $namespaceURI, $name, $value );

    my $fragment = $doc.createDocumentFragment();
    my $cdata = $dom.createCDATASection( $cdata_content );
    my $pi = $doc.createProcessingInstruction( "foo", "bar" );
    my $entref = $doc.createEntityReference("foo");
    my $dtd = $dom.createInternalSubset( $name, $public, $system);

    $dtd = $doc.createExternalSubset( $tagname, $public, $system);
    $doc.importNode( $node );
    $doc.adoptNode( $node );
    $dtd = $doc.externalSubset;
    $dtd = $doc.internalSubset;
    $doc.setExternalSubset($dtd);
    $doc.externalSubset = $dtd;
    $doc.setInternalSubset($dtd);
    $doc.internalSubset = $dtd;
    $dtd = $doc.removeExternalSubset();
    $dtd = $doc.removeInternalSubset();
    my @nodelist = $doc.getElementsByTagName($tagname);
    @nodelist = $doc.getElementsByTagNameNS($URI,$tagname);
    @nodelist = $doc.getElementsByLocalName('localname');
    $node = $doc.getElementById('x');
    $doc.indexElements();

    if $*DISTRO.is-win {
        skip 'todo - proper encoding/iconv on Windows', 2;
    }
    else {
        $doc = LibXML.createDocument( '1.0', "ISO-8859-15" );
        is $doc.encoding, 'ISO-8859-15';
        $doc .= parse(' <x>zzz</x>');
        is $doc.root.Str, '<x>zzz</x>';
    }
};

subtest 'LibXML::DocumentFragment' => {
    plan 3;
    use LibXML::Document;
    use LibXML::DocumentFragment;

    my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
    is $frag, '<foo/><bar/>';
    $frag.parse: :balanced, :string('<baz/>');
    is $frag.Str, '<foo/><bar/><baz/>';

    my LibXML::Document $dom .= new;
    $frag = $dom.createDocumentFragment;
    $frag.appendChild: $dom.createElement('foo');
    $frag.appendChild: $dom.createElement('bar');
    is $frag.Str, '<foo/><bar/>';
}

subtest 'LibXML::Dtd' => {
    plan 2;
    use LibXML::Dtd;
    lives-ok {
        my LibXML::Dtd $dtd .= parse: :string(q:to<EOF>);
        <!ELEMENT test (#PCDATA)>
        EOF
       $dtd.getName();
    }, 'parse :string';

    lives-ok {
        my LibXML::Dtd $dtd .= new(
            "SOME // Public / ID / 1.0",
            "samples/test.dtd"
           );
        $dtd.getName();
        $dtd.publicId();
        $dtd.systemId();
        $dtd.is-XHTML;
    }, 'new public';

}

subtest 'LibXML::Element' => {
    plan 9;
    use LibXML::Attr;
    use LibXML::Attr::Map;
    use LibXML::Node;
    use LibXML::Document;

    #++ setup
    my $name = 'test-elem';
    my $aname = 'ns:att';
    my $avalue = 'my-val';
    my Str $value;
    my $localname = 'fred';
    my $nsURI = 'http://test.org';
    my $newURI = 'http://test2.org';
    my $tagname = 'elem';
    my LibXML::Document $dom .= new;
    my $chunk = '<a>XXX</a><b/>';
    my $PCDATA = 'PC Data';
    my $nsPrefix = 'foo';
    my $newPrefix = 'bar';
    my $childname = 'kid';
    my LibXML::Element $elem;
    my LibXML::Attr $attrnode .= create: :from($dom), :name<att-key>, :value<att-val>;
    my Bool $boolean;
    my $activate = True;
    my Str $xpath-expression = '*';
    #-- setup

    $elem .= new($name);

    # -- Attribute Methods -- #
    $elem.setAttribute( $aname, $avalue );
    $elem.setAttributeNS( $nsURI, $aname, $avalue );
    is $elem.Str, qq{<test-elem xmlns:ns="$nsURI" $aname="$avalue"/>};
    $elem.setAttributeNode($attrnode, :ns);
    $elem.removeAttributeNode($attrnode);
    $value = $elem.getAttribute( $aname );
    $value = $elem.getAttributeNS( $nsURI, $aname );
    $attrnode = $elem.getAttributeNode( $aname );
    $attrnode = $elem{'@'~$aname}; # xpath attribute selection
    $attrnode = $elem.getAttributeNodeNS( $nsURI, $aname );
    my Bool $has-atts = $elem.hasAttributes();
    my LibXML::Attr::Map $attrs = $elem.attributes();
    my LibXML::Attr @props = $elem.properties();
    $elem.removeAttribute( $aname );
    $elem.removeAttributeNS( $nsURI, $aname );
    $boolean = $elem.hasAttribute( $aname );
    $boolean = $elem.hasAttributeNS( $nsURI, $aname );

    # -- Navigation Methods -- #
    my LibXML::Node @nodes = $elem.getChildrenByTagName($tagname);
    @nodes = $elem.getChildrenByTagNameNS($nsURI,$tagname);
    @nodes = $elem.getChildrenByLocalName($localname);
    @nodes = $elem.children; # all child nodes
    @nodes = $elem.children(:!blank); # non-blank child nodes

    my LibXML::Element @elems = $elem.getElementsByTagName($tagname);
    @elems = $elem.getElementsByTagNameNS($nsURI,$localname);
    @elems = $elem.getElementsByLocalName($localname);
    @elems = $elem.elements();

    #-- DOM Manipulation Methods -- #
    $elem.appendWellBalancedChunk( $chunk );
    $elem.addNewChild( $nsURI, $name );
    $elem.appendText( $PCDATA );
    $elem.appendTextNode( $PCDATA );
    $elem.appendTextChild( $childname , $PCDATA );
    $elem.setNamespace( $nsURI , $nsPrefix, :$activate );
    $elem.setNamespaceDeclURI( $nsPrefix, $newURI );
    $elem.setNamespaceDeclPrefix( $nsPrefix, $newPrefix );

    # Associative interface
    @nodes = $elem{$xpath-expression};  # xpath node selection
    my LibXML::Node @as = $elem<a>;  # equivalent to: $elem.findnodes<a>;
    my @z-grand-kids = $elem<*/z>;   # equiv: $elem.findnodes<*/z>;
    $elem.setAttributeNS( $nsURI, $aname, $avalue );
    is $elem<@ns:att>.Str, "my-val";
    is $elem[0].Str, '<a>XXX</a>';
    is-deeply $elem[0]<text()>.Str, 'XXX';
    is-deeply $elem.keys.sort, <@ns:att a b kid ns:test-elem text()>;
    is-deeply $elem.attributes.keys.sort, ("ns:att", );
    is-deeply $elem.childNodes.keys, (0, 1, 2, 3, 4);
    my $bs = $elem<b>:delete;
    is $bs[0].Str, '<b/>';

    # verify detailed handling of namespaces, as documented for setAttributeNS
    my $aname2 = 'ns2:att2';
    my $avalue2 = 'my-val2';
    $elem.setAttributeNS( $nsURI, $aname2, $avalue2 );
    is $elem<@ns:att2>, $avalue2;
}

subtest 'LibXML::InputCallback' => {
    plan 1;
    my class MyScheme{
        subset URI of Str where .starts-with('myscheme:');
        our class Handler {
            has URI:D $.uri is required;
            has Bool $!first = True;

            method read($len) {
                ($!first-- ?? '<helloworld/>' !! '').encode;
            }
            method close {$!first = True}
        }
    }
    use LibXML::Document;
    use LibXML::Parser;
    use LibXML::InputCallback;
    use LibXML::Config;
    # Define the four callback functions
    sub match-uri(Str $uri) {
        $uri ~~ MyScheme::URI:D; # trigger our callback group at a 'myscheme' URIs
    }

    sub open-uri(MyScheme::URI:D $uri) {
        MyScheme::Handler.new(:$uri);
    }

    # The returned $buffer will be parsed by the libxml2 parser
    sub read-uri(MyScheme::Handler:D $handler, UInt $n --> Blob) {
        $handler.read($n);
    }

    # Close the handle associated with the resource.
    sub close-uri(MyScheme::Handler:D $handler) {
        $handler.close;
    }


    my LibXML::Parser $parser .= new;
    $parser.config.parser-locking = True;

    # Register them with a instance of LibXML::InputCallback
    my LibXML::InputCallback $input-callbacks = $parser.create: LibXML::InputCallback, :trace;
    $input-callbacks.register-callbacks(&match-uri, &open-uri,
                                        &read-uri, &close-uri );
    # Register the callback group at a parser instance
    $parser.input-callbacks = $input-callbacks;

    my LibXML::Document:D $doc = $parser.parse: :file('myscheme:muahahaha.xml');
    is $doc.root.Str, '<helloworld/>';
}

subtest 'LibXML::Namespace' => {
    plan 12;
    use LibXML::Namespace;
    use LibXML::Attr;
    my $URI = 'http://test.org';
    my $prefix = 'tst';
    my LibXML::Namespace $ns .= new: :$URI, :$prefix;
    is $ns.declaredURI, $URI, 'declaredURI';
    is $ns.declaredPrefix, $prefix, 'declaredPrefix';
    is $ns.nodeName, 'xmlns:'~$prefix, 'nodeName';
    is $ns.name, 'xmlns:'~$prefix, 'nodeName';
    is $ns.localname, $prefix, 'localName';
    is $ns.getValue, $URI, 'getValue';
    is $ns.value, $URI, 'value';
    is $ns.getNamespaceURI, 'http://www.w3.org/2000/xmlns/';
    is $ns.prefix, 'xmlns';
    ok $ns.unique-key, 'unique_key sanity';
    my LibXML::Namespace $ns-again = $ns.create(LibXML::Namespace, :$URI, :$prefix);
    my LibXML::Namespace $ns-different = $ns.create(LibXML::Namespace, URI => $URI~'X', :$prefix);
    is $ns.unique-key, $ns-again.unique-key, 'Unique key match';
    isnt $ns.unique-key, $ns-different.unique-key, 'Unique key non-match';

};

subtest 'LibXML::Node' => {
    plan 14;
    use LibXML::Node;
    use LibXML::Node::Set;
    use LibXML::Element;
    use LibXML::Namespace;

    #++ setup
    my LibXML::Document $doc       .= new;
    my LibXML::Element $node        = $doc.create: LibXML::Element, :name<Alice>;
    my LibXML::Element $other-node  = $doc.create: LibXML::Element, :name<Xxxx>;
    my LibXML::Element $childNode   = $doc.create: LibXML::Element, :name<Bambi>;
    my LibXML::Element $newNode     = $doc.create: LibXML::Element, :name<NewNode>;
    my LibXML::Element $oldNode     = $childNode;
    my LibXML::Element $refNode     = $doc.create: LibXML::Element, :name<RefNode>;
    my LibXML::Element $parent      = $doc.create: LibXML::Element, :name<Parent>;
    my Str $nsURI = 'http://ns.org';
    my Str $xpath-expression = '*';
    my Str $newName = 'Bob';
    $node.addChild($childNode);
    $parent.addChild($node);
    $parent.setOwnerDocument($doc);
    #-- setup

    # -- Property Methods -- #
    my Str $name = $node.nodeName;
    $node.setNodeName( $newName );
    $node.nodeName = $newName;
    my Bool $same = $node.isSameNode( $other-node );
    my Str $key = $node.unique-key;
    my Str $content = $node.nodeValue;
    $content = $node.textContent;
    my UInt $type = $node.nodeType;
    lives-ok {$node.setBaseURI('file://t/99doc-examples.t');}
    is $node.getBaseURI, 'file://t/99doc-examples.t', 'getBaseURI';
    is $node.nodePath, '/Parent/Bob';
    is $node.line-number(), '0';

    # -- Navigation Methods -- #
    $parent = $node.parentNode;
    my LibXML::Node $next = $node.nextSibling();
    $next = $node.nextNonBlankSibling();
    my LibXML::Node $prev = $node.previousSibling();
    $prev = $node.previousNonBlankSibling();
    my Bool $is-parent = $node.hasChildNodes();
    my LibXML::Node $child = $node.firstChild;
    $child = $node.lastChild;
    $other-node = $node.getOwner;
    $node.appendChild($refNode);
    $node.insertBefore( $newNode, $refNode );
    $node.insertAfter( $newNode, $refNode );
    my LibXML::Node @kids = $node.childNodes();
    @kids = $node.nonBlankChildNodes();

    # -- DOM Manipulation Methods ---
    $node.unbindNode();
    $node.ownerDocument = $doc;
    ok $node.ownerDocument.isSameNode($doc);
    $doc.documentElement = $node;
    $child = $node.removeChild( $childNode );
    $oldNode = $node.replaceChild( $newNode, $oldNode );
    $node.replaceNode($newNode);
    $childNode = $node.appendChild( $childNode );
    ok $node.isSame($childNode.parent);
    $node = $parent.addNewChild( $nsURI, $name );
    $node.addSibling($newNode);
    $newNode = $node.cloneNode( :deep );
    $node.addChild($refNode);
    ok $node.isSame($refNode.parent);
    $node.insertBefore( $newNode, $refNode );
    $node.insertAfter( $newNode, $refNode );
    $node.removeChildNodes();
    $node.ownerDocument = $doc;

    # -- Searching Methods --
    @kids = $node.findnodes( $xpath-expression );
    my LibXML::Node::Set $result = $node.find( $xpath-expression );
    print $node.findvalue( $xpath-expression );
    my Bool $found = $node.exists( $xpath-expression );
    $found = $xpath-expression ~~ $node;
    my LibXML::Node $item = $node.first( $xpath-expression );
    $item = $node.last( $xpath-expression );

    # -- Serialization Methods -- #
    my Str $xml = $node.Str(:format);
    my Str $xml-c14n = $doc.Str: :C14N;
    $xml-c14n = $node.Str: :C14N, :comments, :xpath($xpath-expression);
    $xml-c14n = $node.Str: :C14N, :xpath($xpath-expression), :exclusive;
    $xml-c14n = $node.Str: :C14N, :v(v1.1);
    $xml = $doc.serialize(:format);
    # -- Binary serialization -- #
    my blob8 $buf = $node.Blob(:format, :enc<UTF-8>);
    # -- Data serialization -- #
    use LibXML::Item :ast-to-xml;
    my $node-data = $node.ast;
    my LibXML::Node $node2 = ast-to-xml($node-data);
    is $node, $node2, 'ast round-trip';

    # -- Namespace Methods --
    my Str $localname = $node.localname;
    my Str $prefix = $node.prefix;
    my Str $uri = $node.namespaceURI();
    my Bool $has-atts = $node.hasAttributes();
    $uri = $node.lookupNamespaceURI( $prefix );
    $prefix = $node.lookupNamespacePrefix( $uri );
    $node.normalize;
    my LibXML::Namespace @ns = $node.getNamespaces;
    $node.removeChildNodes();
    $uri = $node.baseURI();
    $node.setBaseURI($uri);
    $node.nodePath();
    my UInt $line-no = $node.line-number();

    # -- Positional Interface --
    $node = $doc.create: $node, :name<Test>;
    $node.push: $doc.create: LibXML::Element, :name<A>;
    $node.push: $doc.create: LibXML::Element, :name<B>;
    is $node.Str, '<Test><A/><B/></Test>';
    is $node[1].Str, '<B/>';
    is $node.values.map(*.Str).join(':'), '<A/>:<B/>';
    $node[1] = $doc.create: LibXML::Element, :name<C>;
    $node[2] = $doc.create: LibXML::Element, :name<D>;
    dies-ok { $node[42] = $doc.create: LibXML::Element, :name<Z>; }
    is $node.Str, '<Test><A/><C/><D/></Test>';
    $node.pop;
    $node.pop;
    is $node.Str, '<Test><A/></Test>';
}

sub test-option($obj, Str $option, *@values, :$default) {
    my $what = $obj.WHAT.gist;
    my $orig = $obj."$option"();
    is-deeply($orig, $_, "$what $option default value")
        with $default;
    for @values {
        $obj.set-option($option, $_);
        is $obj.get-option($option), $_, "$what set/get of $option option";
    }
    $obj."$option"() = $orig;
    is $obj.get-option($option), $orig, "$what restore of $option option";

}

subtest 'LibXML::Parser' => {
    plan 103;
    use LibXML;
    use LibXML::Reader;
    my LibXML $parser .= new;
    my $file = "test/textReader/countries.xml";
    my LibXML::Reader $reader .= new(location => $file);

    test-option($_, 'html', True, :default(False))
        for $parser;

    test-option($_, 'no-html', False, :default(True))
        for $parser;

    test-option($_, 'line-numbers', True, :default(False))
        for $parser;
    skip "does the reader really handle line-numbers option?";

    test-option($_, 'enc', 'UTF-16')
        for $parser;
    lives-ok { $reader.enc }, "reader 'enc' option (read-only)";

    test-option($_, 'recover', True, :default(False))
        for $parser, $reader;

    test-option($_, 'expand-entities', False, :default(False))
        for $parser, $reader;

    test-option($_, 'complete-attributes', True, :default(False))
        for $parser, $reader;

    test-option($_, 'validation', True, :default(False))
        for $parser, $reader;

    test-option($_, 'suppress-errors', True, :default(False))
        for $parser, $reader;

    test-option($_, 'suppress-warnings', True, :default(False))
        for $parser, $reader;

    test-option($_, 'pedantic-parser', True, :default(False))
        for $parser, $reader;

    test-option($_, 'no-blanks', True, :default(False))
        for $parser, $reader;

    test-option($_, 'blanks', False, :default(True))
        for $parser, $reader;

    test-option($_, 'expand-xinclude', True, :default(False))
        for $parser, $reader;

    test-option($_, 'xinclude-nodes', False, :default(True))
        for $parser, $reader;

    test-option($_, 'clean-namespaces', True, :default(False))
        for $parser, $reader;

    test-option($_, 'cdata', False, :default(True))
        for $parser, $reader;

    test-option($_, 'base-fix', False, :default(True))
        for $parser, $reader;

    test-option($_, 'huge', True, :default(False))
        for $parser, $reader;

}

subtest 'LibXML::PI' => {
    plan 2;
    use LibXML::Document;
    use LibXML::PI;
    my LibXML::Document $dom .= new;
    my LibXML::PI $pi = $dom.createProcessingInstruction("abc");

    $pi.setData('zzz');
    $dom.appendChild( $pi );
    like $dom.Str, /'<?abc zzz?>'/, 'setData (hash)';

    $pi.setData(foo=>'bar', foobar=>'foobar');
    like $dom.Str, /'<?abc foo="bar" foobar="foobar"?>'/, 'setData (hash)';
    $dom.insertProcessingInstruction("abc",'foo="bar" foobar="foobar"');
};

subtest 'LibXML::RegExp' => {
    plan 2;
    use LibXML::RegExp;
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my LibXML::RegExp $compiled-re .= new( :$regexp );
    ok $compiled-re.matches('12345'), 'matches';
    ok $compiled-re.isDeterministic, 'isDeterministic';
};

subtest 'LibXML::XPath::Expression' => {
    plan 1;
    use LibXML::XPath::Expression;
    my LibXML::XPath::Expression $compiled-xpath .= parse('//foo[@bar="baz"][position()<4]');
    pass;
};

subtest 'LibXML::Text' => {
    plan 22;
    use LibXML::Text;

    #++ setup
    my LibXML::Text $text .= new: :content<xx>;
    my Str $text-content = 'Some text!';
    my UInt $offset = 2;
    my UInt $length = 4;
    my Str $string = '****';
    my Str $somedata = 'XXX';
    my Str $remstring = 'X';
    #-- setup

    # Stringy Interface
    $text.data = $text-content;
    is $text.data, 'Some text!';
    $text.data   ~~ s/(<[a..z]>)/{$0.uc}/;
    is $text.data, 'SOme text!';
    $text.data   ~~ s:g/(<[a..z]>)/{$0.uc}/;
    is $text.data, 'SOME TEXT!';
    $text.data = $text-content;
    my $substr    = $text.substr($offset, $length);
    is $substr, 'me t';
    $text.data   ~= $somedata ;
    is $text.data, 'Some text!XXX';
    $text.data.substr-rw($offset, 0) = $string;
    is $text.data, 'So****me text!XXX';
    $text.data.substr-rw($offset, $length) = '';
    is $text.data, 'Some text!XXX';
    $text.data   ~~ s/$remstring//;
    is $text.data, 'Some text!XX';
    $text.data   ~~ s:g/$remstring//;
    is $text.data, 'Some text!';
    $text.data.substr-rw($offset, $length) = $string;
    is $text.data, 'So****ext!';
    $text.data ~~ s/<[a..z]>/-/;
    is $text.data, 'S-****ext!';
    $text.data ~~ s:g/<[a..z]>/-/;
    is $text.data, 'S-****---!';
    
    # DOM Interface
    $text.setData( $text-content );
    is $text.data, 'Some text!';
    $substr = $text.substringData($offset, $length);
    is $substr, 'me t';
    $text.appendData( $somedata );
    is $text.data, 'Some text!XXX';
    $text.insertData($offset, $string);
    is $text.data, 'So****me text!XXX';
    $text.deleteData($offset, $length);
    is $text.data, 'Some text!XXX';
    $text.deleteDataString($remstring);
    is $text.data, 'Some text!XX';
    $text.deleteDataString($remstring, :g);
    is $text.data, 'Some text!';
    $text.replaceData($offset, $length, $string);
    is $text.data, 'So****ext!';
    $text.replaceDataString(rx/<[a..z]>/, '-');
    is $text.data, 'S-****ext!';
    $text.replaceDataString(rx/<[a..z]>/, '-', :g);
    is $text.data, 'S-****---!';
}

subtest 'LibXML::XPath::Context' => {
    plan 6;
    use LibXML::XPath::Context;
    use LibXML::Node;

    #++ setup
    use LibXML::Element;
    my LibXML::Element $node .= new: :name<Test>;
    my LibXML::Element $ref-node .= new: :name<Test2>;
    my Str $prefix = 'foo';
    my Str $namespace-uri = 'http://ns.org';
    my $xpath = '//foo[@bar="baz"][position()<4]';
    my %variables = (
            'a' => 2,
            'b' => "b",
            );

    sub get-variable($name, $uri ) {
        %variables{$name};
    }
    sub callback(|c) {}
    my Str $name = 'bar';
    #-- setup

    my LibXML::XPath::Context $xpc .= new(:$node);
    $xpc.registerNs($prefix, $namespace-uri);
    $xpc.unregisterNs($prefix);
    my Str $uri = $xpc.lookupNs($prefix);
    $xpc.registerVarLookupFunc(&get-variable);
    my &func = $xpc.getVarLookupFunc();
    $xpc.unregisterVarLookupFunc;
    $xpc.registerFunctionNS($name, $uri, &callback);
    $xpc.unregisterFunctionNS($name, $uri);
    $xpc.registerFunction($name, &callback);
    $xpc.unregisterFunction($name);
    my @nodes = $xpc.findnodes($xpath);
    @nodes = $xpc.findnodes($xpath, $ref-node );
    my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $ref-node );
    my Any $object = $xpc.find($xpath );
    $object = $xpc.find($xpath, $ref-node );
    my Str $value = $xpc.findvalue($xpath );
    $value = $xpc.findvalue($xpath, $ref-node );
    my Bool $found = $xpc.exists( $xpath, $ref-node );

    $xpc.setContextNode($node);
    $node = $xpc.getContextNode;
    $xpc.contextNode = $node;

    my Int $position = $xpc.getContextPosition;
    $xpc.setContextPosition($position);
    $xpc.contextPosition = $position;

    my Int $size = $xpc.getContextSize;
    $xpc.setContextSize($size);
    $xpc.contextSize = $size;

    sub grep-nodes(LibXML::Node::Set $nodes, Str $regex) {
        $nodes.grep: {.textContent ~~ / <$regex> /}
    };

    my LibXML::Document $doc .= parse: "samples/article.xml";
    $node = $doc.root;
    my LibXML::XPath::Context $xc = $doc.create(LibXML::XPath::Context, :$node);
    $xc.registerFunction('grep-nodes', &grep-nodes);
    @nodes = $xc.findnodes('grep-nodes(section,"^Bar")').list;
    is +@nodes, 2;
    like @nodes[0].textContent, /^Bar/;
    like @nodes[1].textContent, /^Bar/;

    {
        use LibXML;
        sub var-lookup(Str $name, Str $uri, Hash $data, :$opt) {
            is $name, 'A', 'var lookup name';
            is $opt, 42, 'var option argument';
            isa-ok $data{$name}, 'LibXML::Node::Set', 'var lookup data';
            return $data{$name};
        }

        my $areas = LibXML.parse: :file('samples/article.xml');
        my $empl = LibXML.parse: :file('samples/test.xml');
  
        my LibXML::XPath::Context $xc = $doc.create(LibXML::XPath::Context, node => $empl);
  
        my %variables = (
            A => $xc.find('/employees/employee[@salary>10000]'),
            B => $areas.find('samples/article.xml'),
        );
  
        # get names of employees from $A working in an area listed in $B
        $xc.registerVarLookupFunc(&var-lookup, %variables, :opt(42));
        my @nodes = $xc.findnodes('$A[work_area/street = $B]/name');
    }

};

subtest 'LibXML::Raw' => {
    plan 1;
    do {
        use LibXML::Raw;
        my xmlDoc:D $doc .= new;
        my xmlElem:D $root = $doc.new-node: :name<Hello>, :content<World!>;
        .Reference for $doc, $root;
        $doc.SetRootElement($root);
        is $doc.Str.lines[1], "<Hello>World!</Hello>";
        .Unreference for $root, $doc;
    }
}

done-testing
