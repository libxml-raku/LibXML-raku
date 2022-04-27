use Test;
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

    {
        my LibXML $ctx .= new: :$config;
        cmp-ok $ctx.config, '===', $config, 'configured LibXML';
    }
}

done-testing;
