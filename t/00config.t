use Test;
plan 4;
use LibXML::Config;

subtest 'scoping', {
    my LibXML::Config:U $cu;
    my LibXML::Config:D $cd .= new;

    is-deeply $cu.skip-xml-declaration, False;
    is-deeply $cd.skip-xml-declaration, False;

    $cu.skip-xml-declaration = True;

    is-deeply $cu.skip-xml-declaration, True;
    is-deeply $cd.skip-xml-declaration, False;

    $cu.skip-xml-declaration = False;
    $cd.skip-xml-declaration = True;

    is-deeply $cu.skip-xml-declaration, False;
    is-deeply $cd.skip-xml-declaration, True;
}

subtest 'construct', {
    my LibXML::Config:D $cd .= new: :skip-xml-declaration, :skip-dtd, :max-errors(42);
    is-deeply $cd.skip-xml-declaration, True, 'skip-xml-declaration';
    is-deeply $cd.skip-dtd, True, 'skip-dtd';
    is-deeply $cd.max-errors, 42;
}

subtest 'propagation', {
    use LibXML;
    use LibXML::XPath::Context;
    use LibXML::Reader;

    my LibXML::Config:D $config .= new: :skip-xml-declaration, :max-errors(42);
    {
        my LibXML $impl .= new: :$config;
        cmp-ok $impl.config, '===', $config, 'configured LibXML';
    }

    {
        my LibXML::XPath::Context $ctx .= new: :$config;
        cmp-ok $ctx.config, '===', $config, 'configured LibXML::XPath::Context';
    }

    {
        my LibXML::Reader $ctx .= new: :string("<test/>"), :$config;
        cmp-ok $ctx.config, '===', $config, 'configured LibXML::Reader';
    }

}

subtest 'node', {
    use LibXML::Document;
    use LibXML::XPath::Context;;

    my LibXML::Document:D $doc .= parse: :string("<test/>");
    my LibXML::Config:D $config .= new: :skip-xml-declaration, :max-errors(42);

    lives-ok {$doc.root.appendWellBalancedChunk("<a/><b/><c/>", :$config);}

    my LibXML::XPath::Context $ctx = $doc.root.xpath-context: :$config;
    cmp-ok $ctx.config, '===', $config, 'configured node xpath-context';

    my $str = $doc.Str;
    ok $str.starts-with("<?xml"), 'Str without config :!skip';

    $str = $doc.Str: :$config;
    nok $str.starts-with("<?xml"), 'Str with config :skip';

    LibXML::Config.skip-xml-declaration = True;
    $str = $doc.Str;
    nok $str.starts-with("<?xml"), 'Str without config :skip';

    $config.skip-xml-declaration = False;
    $str = $doc.Str: :$config;
    ok $str.starts-with("<?xml"), 'Str with config :!skip';
}

done-testing;
