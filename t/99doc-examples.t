# test synopsis and code samples in POD Documentation

use Test;

plan 17;

subtest 'LibXML::Attr' => {
    plan 5;
    use LibXML::Attr;
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

    my LibXML::Attr $style .= new: :name<style>, :value('fontweight: bold');
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
    my LibXML::Document $doc .= parse("example/dtd.xml", :dtd);
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
    is $URI, "example/dtd.xml";
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
    $str = $doc.Str: :HTML;
    like $str, /'<!DOCTYPE doc>'/;
    $str = $doc.serialize-html();
    like $str, /'<!DOCTYPE doc>'/;
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

    $doc = LibXML.createDocument;
    $doc = LibXML.createDocument( '1.0', "ISO-8859-15" );
    is $doc.encoding, 'ISO-8859-15';
    $doc .= parse(' <x>zzz</x>');
    is $doc.root.Str, '<x>zzz</x>';
};

subtest 'LibXML::DocumentFragment' => {
    plan 1;
    use LibXML::Document;
    use LibXML::DocumentFragment;
    my LibXML::Document $dom .= new;
    my LibXML::DocumentFragment $frag = $dom.createDocumentFragment;
    $frag.appendChild: $dom.createElement('foo');
    $frag.appendChild: $dom.createElement('bar');
    is $frag.Str, '<foo/><bar/>';
}

subtest 'LibXML::Dtd' => {
    plan 2;
    use LibXML::Dtd;
    lives-ok {
        my $dtd = LibXML::Dtd.parse: :string(q:to<EOF>);
        <!ELEMENT test (#PCDATA)>
        EOF
       $dtd.getName();
    }, 'parse :string';

    lives-ok {
        my $dtd = LibXML::Dtd.new(
            "SOME // Public / ID / 1.0",
            "example/test.dtd"
           );
        $dtd.getName();
        $dtd.publicId();
        $dtd.systemId();
    }, 'new public';

}

subtest 'XML::LibXML::Element' => {
    plan 1;
    use LibXML::Attr;
    use LibXML::Attr::Map;
    use LibXML::Node;
    use LibXML::Document;
    my $name = 'test-elem';
    my $aname = 'ns:att';
    my $avalue = 'my-val';
    my $localname = 'fred';
    my $nsURI = 'http://test.org';
    my $newURI = 'http://test2.org';
    my $tagname = 'elem';
    my LibXML::Node @nodes;
    my LibXML::Document $dom .= new;
    my $chunk = '<a>XXX</a><b/>';
    my $PCDATA = 'PC Data';
    my $nsPrefix = 'foo';
    my $newPrefix = 'bar';
    my $childname = 'kid';
    my LibXML::Element $node;
    my $attrnode;
    my Bool $boolean;
    my $activate = True;
    $node .= new( $name );
    $node.setAttribute( $aname, $avalue );
    $node.setAttributeNS( $nsURI, $aname, $avalue );
    $avalue = $node.getAttribute( $aname );
    $avalue = $node.getAttributeNS( $nsURI, $aname );
    $attrnode = $node.getAttributeNode( $aname );
    $attrnode = $node.getAttributeNodeNS( $nsURI, $aname );
    my LibXML::Attr::Map $attrs = $node.attributes();
    my LibXML::Attr @props = $node.properties();
    $node.removeAttribute( $aname );
    $node.removeAttributeNS( $nsURI, $aname );
    $boolean = $node.hasAttribute( $aname );
    $boolean = $node.hasAttributeNS( $nsURI, $aname );
    @nodes = $node.getChildrenByTagName($tagname);
    @nodes = $node.getChildrenByTagNameNS($nsURI,$tagname);
    @nodes = $node.getChildrenByLocalName($localname);
    @nodes = $node.getElementsByTagName($tagname);
    @nodes = $node.getElementsByTagNameNS($nsURI,$localname);
    @nodes = $node.getElementsByLocalName($localname);
    $node.appendWellBalancedChunk( $chunk );
    $node.appendText( $PCDATA );
    $node.appendTextNode( $PCDATA );
    $node.appendTextChild( $childname , $PCDATA );
    $node.setNamespace( $nsURI , $nsPrefix, :$activate );
    $node.setNamespaceDeclURI( $nsPrefix, $newURI );
    $node.setNamespaceDeclPrefix( $nsPrefix, $newPrefix );

    # verify detailed handling of namespaces, as documented for setAttributeNS
    my $aname2 = 'ns2:att2';
    my $avalue2 = 'my-val2';
    $node.setAttributeNS( $nsURI, $aname2, $avalue2 );
    is $node<@ns:att2>, $avalue2;
}

subtest 'XML::LibXML::InputCallback' => {
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

    # Register them with a instance of LibXML::InputCallback
    my LibXML::InputCallback $input-callbacks .= new: :trace;
    $input-callbacks.register-callbacks(&match-uri, &open-uri,
                                        &read-uri, &close-uri );

    my LibXML::Parser $parser .= new;
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
    my LibXML::Namespace $ns-again .= new(:$URI, :$prefix);
    my LibXML::Namespace $ns-different .= new(URI => $URI~'X', :$prefix);
    todo "implment unique key?";
    is $ns.unique-key, $ns-again.unique-key, 'Unique key match';
    isnt $ns.unique-key, $ns-different.unique-key, 'Unique key non-match';

};

subtest 'LibXML::Node' => {
    plan 8;
    use LibXML::Node;
    use LibXML::Element;
    use LibXML::Namespace;

    #++ setup
    my LibXML::Element $node       .= new: :name<Alice>;
    my LibXML::Element $other-node .= new: :name<Xxxx>;
    my LibXML::Element $childNode  .= new: :name<Bambi>;
    my LibXML::Element $newNode    .= new: :name<NewNode>;
    my LibXML::Element $oldNode     = $childNode;
    my LibXML::Element $refNode    .= new: :name<RefNode>;
    my LibXML::Element $parent     .= new: :name<Parent>;
    $node.addChild($childNode);
    my Str $nsURI = 'http://ns.org';
    my Str $xpath-expression = '*';
    my Str $enc = 'UTF-8';
    #-- setup

    my Str $newName = 'Bob';
    my Str $name = $node.nodeName;
    $node.setNodeName( $newName );
    $node.nodeName = $newName;
    my Bool $same = $node.isSameNode( $other-node );
    my Str $key = $node.unique-key;
    my Str $content = $node.nodeValue;
    $content = $node.textContent;
    my UInt $type = $node.nodeType;
    $node.unbindNode();
    my LibXML::Node $child = $node.removeChild( $childNode );
    $oldNode = $node.replaceChild( $newNode, $oldNode );
    $node.replaceNode($newNode);
    $childNode = $node.appendChild( $childNode );
    $childNode = $node.addChild( $childNode );
    ok $node.isSame($childNode.parent);
    $node = $parent.addNewChild( $nsURI, $name );
    $node.addSibling($newNode);
    $newNode = $node.cloneNode( :deep );
    $parent = $node.parentNode;
    my LibXML::Node $next = $node.nextSibling();
    $next = $node.nextNonBlankSibling();
    my LibXML::Node $prev = $node.previousSibling();
    $prev = $node.previousNonBlankSibling();
    my Bool $is-parent = $node.hasChildNodes();
    $child = $node.firstChild;
    $child = $node.lastChild;
    my LibXML::Document $doc = $node.ownerDocument;
    $doc = $node.getOwner;
    $doc .= new;
    $node.setOwnerDocument( $doc );
    $node.ownerDocument = $doc;
    ok $node.ownerDocument.isSameNode($doc);
    $doc.documentElement = $node;
    $node.appendChild($refNode);
    $node.insertBefore( $newNode, $refNode );
    $node.insertAfter( $newNode, $refNode );
    my LibXML::Node @kids = $node.findnodes( $xpath-expression );
    my LibXML::Node::Set $result = $node.find( $xpath-expression );
    print $node.findvalue( $xpath-expression );
    my Bool $found = $node.exists( $xpath-expression );
    @kids = $node.childNodes();
    @kids = $node.nonBlankChildNodes();
    my Str $xml = $node.Str(:format);
    my Str $xml-c14n = $doc.Str: :C14N;
    $xml-c14n = $node.Str: :C14N, :comments, :xpath($xpath-expression);
    $xml-c14n = $node.Str: :C14N, :xpath($xpath-expression), :exclusive;
    $xml-c14n = $node.Str: :C14N, :v(v1.1);
    $xml = $doc.serialize(:format);
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

    # Positional Interface to child nodes
    $node .= new: :name<Test>;
    $node.push: LibXML::Element.new: :name<A>;
    $node.push: LibXML::Element.new: :name<B>;
    is $node.Str, '<Test><A/><B/></Test>';
    is $node[1].Str, '<B/>';
    is $node.values.map(*.Str).join(':'), '<A/>:<B/>';
    $node[1] = LibXML::Element.new: :name<C>;
    $node[2] = LibXML::Element.new: :name<D>;
    dies-ok { $node[42] = LibXML::Element.new: :name<Z>; }
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

    test-option($_, 'expand-entities', False, :default(True))
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
    my LibXML::XPath::Expression:D $compiled-xpath .= parse('//foo[@bar="baz"][position()<4]');
    pass;
};

subtest 'LibXML::Text' => {
    plan 20;
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

    my LibXML::XPath::Context $xpc .= new();
    $xpc .= new(:$node);
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

    my LibXML::Document $doc .= parse: "example/article.xml";
    $node = $doc.root;
    my $xc = LibXML::XPath::Context.new(:$node);
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

        my $areas = LibXML.parse: :file('example/article.xml');
        my $empl = LibXML.parse: :file('example/test.xml');
  
        my $xc = LibXML::XPath::Context.new(node => $empl);
  
        my %variables = (
            A => $xc.find('/employees/employee[@salary>10000]'),
            B => $areas.find('example/article.xml'),
        );
  
        # get names of employees from $A working in an area listed in $B
        $xc.registerVarLookupFunc(&var-lookup, %variables, :opt(42));
        my @nodes = $xc.findnodes('$A[work_area/street = $B]/name');
    }

};

done-testing
