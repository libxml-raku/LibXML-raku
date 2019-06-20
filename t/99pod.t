# test code sample in POD Documentation

use Test;

plan 4;

subtest {
    plan 5;
    # -- LibXML::Attr --
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

}, 'LibXML::Attr POD';

subtest {
    plan 2;
    # -- LibXML::PI --
    use LibXML::Document;
    use LibXML::PI;
    my LibXML::Document $dom .= new;
    my LibXML::PI $pi = $dom.createProcessingInstruction("abc");

    $pi.setData('zzz');
    $dom.appendChild( $pi );
    like $dom.Str, /'<?abc zzz?>'/, 'setData (hash)';

    $pi.setData(foo=>'bar', foobar=>'foobar');
    like $dom.Str, /'<?abc foo="bar" foobar="foobar"?>'/, 'setData (hash)';
}, 'LibXML::PI POD';

subtest {
    plan 13;
    # -- LibXML::Namespace --
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

}, 'LibXML::Namespace POD';

subtest {
    plan 2;
    # -- LibXML::RegExp --
    use LibXML::RegExp;
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my LibXML::RegExp $compiled-re .= new( :$regexp );
    ok $compiled-re.matches('12345'), 'matches';
    ok $compiled-re.isDeterministic, 'isDeterministic';
}, 'LibXML::RegExp POD';

done-testing
