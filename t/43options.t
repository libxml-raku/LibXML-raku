use v6;
use Test;
plan 5;

use LibXML;
use LibXML::Config;
use LibXML::Document;
use LibXML::InputCallback;


LibXML::Config.use-global;

my @all = qw<
    recover
    expand_entities
    load_ext_dtd
    complete_attributes
    validation
    suppress_errors
    suppress_warnings
    pedantic_parser
    no_blanks
    expand_xinclude
    xinclude
    network
    clean_namespaces
    no_cdata
    no_xinclude_nodes
    old10
    no_base_fix
    huge
    oldsax
>;

subtest 'setting options', {
    my LibXML $p .= new();
    for @all -> $opt {
        is ?$p.get-option($opt), False, "option $opt default";
    }
    ok ! $p.option-exists('foo'), 'non-existant option';

    is-deeply $p.keep-blanks(), True, 'keep--blanks default' ;
    is-deeply $p.set-option(no_blanks => 1), True, 'set no_blanks';
    ok ! $p.keep-blanks(), 'Get keep-blanks';
    is-deeply $p.keep-blanks(1), True, 'Set keep-blanks to True';
    ok ! $p.get-option('no_blanks'), 'Get no_blanks again';

    my $uri = 'http://foo/bar';
    is $p.set-option(URI => $uri), $uri, 'Set URI';
    is $p.get-option('URI'), $uri, 'Get URI';
    is $p.URI, $uri, 'Get URI';

    subtest 'recover, recover_silently', {
        ok ! $p.recover_silently();
        $p.set-option(recover => 1);
        is-deeply $p.recover_silently(), False;
        $p.set-option(recover => 2);
        is-deeply $p.recover_silently(), True;
        is-deeply $p.recover_silently(0), False;
        is-deeply $p.get-option('recover'), False;
        is-deeply $p.recover_silently(1), True;
        is $p.get-option('recover'), 2;
    }

    subtest 'expand_entities, load_ext_dtd', {
        is-deeply $p.expand_entities(), False;
        is-deeply $p.load_ext_dtd(), False;
        $p.load_ext_dtd(0);
        is-deeply $p.load_ext_dtd(), False;
        $p.expand_entities(0);
        is-deeply $p.expand_entities(), False;
        $p.expand_entities(1);
        is-deeply $p.expand_entities(), True;
    }
}

subtest 'network options', {
    my $XML = q:to<EOT>;
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE title [ <!ELEMENT title ANY >
    <!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
    <rss version="2.0">
    <channel>
        <link>example.com</link>
        <description>XXE</description>
        <item>
            <title>&xxe;</title>
            <link>example.com</link>
            <description>XXE here</description>
        </item>
    </channel>
    </rss>
    EOT

    my $sys_line = q:to<EOT>;
    <title>&xxe;</title>
    EOT

    chomp($sys_line);

    my LibXML $parser .= new(
        :!expand-entities,
        :!load-ext-dtd,
        :!expand-xinclude,
    );
    my LibXML::Document $XML_DOC = $parser.load: string => $XML;

    ok($XML_DOC.Str().contains($sys_line),
        "expand_entities is preserved after _clone()/etc."
      );

    my Bool $net-access = False;
    # now check network access
    $XML ~~ s,'file://',http://example.com,;
    # guard against actual network access attempts
    my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match(sub ($f) {True }),
        :open(sub ($_)  { (/^http[s?]':'/ ?? do { $net-access++; 'test/empty.txt' } !! $_).IO.open(:r); }),
        :read(sub ($fh, $n) {$fh.read($n)}),
        :close(sub ($fh) {$fh.close}),
    };
    $input-callbacks.activate;

    $parser .= new();
    is-deeply $parser.network, False;
    $parser.load_ext_dtd = True;
    $parser.expand_entities = True;
    is-deeply $parser.network, False;
    try { $parser.load: string => $XML };
    like( $!, /'I/O error : Attempt to load network entity'/, 'Entity from network location throw error.' );
    nok $net-access, 'no attempted network access';
    $parser.network = True;
    try { $parser.load: string => $XML };
    ok ! $!.defined, 'attempted network access';
    ok $net-access, 'attempted network access';

}

subtest 'setting all options', {
    my %opts = (map { $_ => True }, @all);
    my LibXML $p .= new: |%opts;
    for @all -> $opt {
        is-deeply ?$p.get-option($opt), True, $opt;
        is-deeply ?$p."$opt"(), True, $opt;
    }

    for @all -> $opt {
        subtest "setting $opt", {
            ok $p.option-exists($opt);
            is-deeply $p.set-option($opt,0), False;
            is-deeply $p.get-option($opt), False;
            is-deeply $p.set-option($opt,1), True;
            # accessors
            is-deeply ?$p.get-option($opt), True;
            is-deeply ?$p."$opt"(), True;
            is-deeply $p."$opt"(0), False;
            is-deeply $p."$opt"(), False;
            is-deeply $p."$opt"(1), True;
        }
    }
}

subtest 'initialize options to False', {
    my %opts = (map { $_ => False }, @all);
    my LibXML $p .= new: |%opts;
    for @all -> $opt {
        is-deeply $p.get-option($opt), False, $opt;
        is-deeply $p."$opt"(), False, $opt;
    }
}

subtest 'initialize options to True', {
    my %opts = (map { $_ => True }, @all);
    my LibXML $p .= new: |%opts;
    for @all -> $opt {
        is-deeply ?$p.get-option($opt), True, $opt;
        is-deeply ?$p."$opt"(), True, $opt;
    }
}

