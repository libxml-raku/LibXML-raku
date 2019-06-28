# test code sample in POD Documentation

use Test;

plan 10;

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

subtest 'LibXML::Comment' => {
    plan 1;
    use LibXML::Comment;
    my LibXML::Comment $node .= new: :content("This is a comment");
    is $node.content, "This is a comment";
}

subtest 'LibXML::CDATASection' => {
    plan 1;
    use LibXML::CDATASection;
    my LibXML::CDATASection $node .= new: :content("This is cdata");
    is $node.content, "This is cdata";
}

subtest 'LibXML::Document' => {
    plan 7;
    use LibXML;
    my $version = '1.0';
    my $enc = 'UTF-8';
    my $numvalue = 1;
    my $ziplevel = 5;
    my Bool $format = True;
    my $doc = LibXML.load: :location("example/dtd.xml"), :dtd;
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

    my $strURI = $doc.URI();
    is $strURI, "example/dtd.xml";
    $doc.setURI($strURI);
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
    ## $doc.write: :$io;
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
    @nodelist = $doc.getElementsByTagNameNS($strURI,$tagname);
    @nodelist = $doc.getElementsByLocalName('localname');
    $node = $doc.getElementById('x');
    $doc.indexElements();

    $doc = LibXML.createDocument;
    $doc = LibXML.createDocument( '1.0', "ISO-8859-15" );
    is $doc.encoding, 'ISO-8859-15';
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

subtest 'XML::LibXML::Element' => {
    plan 1;
    use LibXML::Attr;
    use LibXML::Element;
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
    ok(1);
}

subtest 'LibXML::Namespace' => {
    plan 13;
    use LibXML::Namespace;
    my $URI = 'http://test.org';
    my $prefix = 'tst';
    my LibXML::Namespace $ns .= new: :$URI, :$prefix;
    is $ns.declaredURI, $URI, 'declaredURI';
    is $ns.declaredPrefix, $prefix, 'declaredPrefix';
    is $ns.nodeName, 'xmlns:'~$prefix, 'nodeName';
    is $ns.name, 'xmlns:'~$prefix, 'nodeName';
    is $ns.getLocalName, $prefix, 'localName';
    is $ns.getData, $URI, 'getData';
    is $ns.getValue, $URI, 'getValue';
    is $ns.value, $URI, 'value';
    is $ns.getNamespaceURI, 'http://www.w3.org/2000/xmlns/';
    is $ns.getPrefix, 'xmlns';
    ok $ns.unique-key, 'unique_key sanity';
    my LibXML::Namespace $ns-again .= new(:$URI, :$prefix);
    my LibXML::Namespace $ns-different .= new(URI => $URI~'X', :$prefix);
    todo "implment unique key?";
    is $ns.unique-key, $ns-again.unique-key, 'Unique key match';
    isnt $ns.unique-key, $ns-different.unique-key, 'Unique key non-match';

};

subtest 'LibXML::RegExp' => {
    plan 2;
    use LibXML::RegExp;
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my LibXML::RegExp $compiled-re .= new( :$regexp );
    ok $compiled-re.matches('12345'), 'matches';
    ok $compiled-re.isDeterministic, 'isDeterministic';
};

done-testing
