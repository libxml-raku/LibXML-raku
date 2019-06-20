# test code sample in POD Documentation

use Test;

plan 3;

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
    plan 2;
    # -- LibXML::RegExp --
    use LibXML::RegExp;
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my LibXML::RegExp $compiled-re .= new( :$regexp );
    ok $compiled-re.matches('12345'), 'matches';
    ok $compiled-re.isDeterministic, 'isDeterministic';
}, 'LibXML::RegExp POD';

done-testing
