use v6;
use Test;
plan 332;

use LibXML;
use LibXML::InputCallback;

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

{
  my $p = LibXML.new();
  for @all -> $opt {
    is(? $p.get-option($opt), False, "Testing option $opt");
  }
  ok(! $p.option-exists('foo'), ' TODO : Add test name');

  is-deeply( $p.keep-blanks(), True, ' TODO : Add test name' );
  is-deeply( $p.set-option(no_blanks => 1), True, 'Get no_blanks');
  ok( ! $p.keep-blanks(), 'Get keep-blanks' );
  is-deeply( $p.keep-blanks(1), True, 'Set keep-blanks to True' );
  ok( ! $p.get-option('no_blanks'), ' TODO : Add test name' );

  my $uri = 'http://foo/bar';
  is( $p.set-option(URI => $uri), $uri, 'Set URI');
  is( $p.get-option('URI'), $uri, 'Get URI');
  is( $p.URI, $uri, 'Get URI');

  ok( ! $p.recover_silently(), ' TODO : Add test name' );
  $p.set-option(recover => 1);
  is-deeply( $p.recover_silently(), False, ' TODO : Add test name' );
  $p.set-option(recover => 2);
  is-deeply( $p.recover_silently(), True, ' TODO : Add test name' );
  is-deeply( $p.recover_silently(0), False, ' TODO : Add test name' );
  is-deeply( $p.get-option('recover'), False, ' TODO : Add test name' );
  is-deeply( $p.recover_silently(1), True, ' TODO : Add test name' );
  is( $p.get-option('recover'), 2, ' TODO : Add test name' );

  is-deeply( $p.expand_entities(), False, ' TODO : Add test name' );
  is-deeply( $p.load_ext_dtd(), False, ' TODO : Add test name' );
  $p.load_ext_dtd(0);
  is-deeply( $p.load_ext_dtd(), False, ' TODO : Add test name' );
  $p.expand_entities(0);
  is-deeply( $p.expand_entities(), False, ' TODO : Add test name' );
  $p.expand_entities(1);
  is-deeply( $p.expand_entities(), True, ' TODO : Add test name' );
}

{
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

    my $parser = LibXML.new(
        expand_entities => 0,
        load_ext_dtd    => 0,
        expand_xinclude => 0,
    );
    my $XML_DOC = $parser.load: string => $XML;

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

    $parser = LibXML.new();
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

{
  my %opts = (map { $_ => True }, @all);
  my $p = LibXML.new: |%opts;
  for @all -> $opt {
    is-deeply(?$p.get-option($opt), True, ' TODO : Add test name');
    is-deeply(?$p."$opt"(), True, ' TODO : Add test name')
  }

  for @all -> $opt {
    ok($p.option-exists($opt), ' TODO : Add test name');
    is-deeply($p.set-option($opt,0), False, ' TODO : Add test name');
    is-deeply($p.get-option($opt), False, ' TODO : Add test name');
    is-deeply($p.set-option($opt,1), True, ' TODO : Add test name');
    # accessors
    is-deeply(? $p.get-option($opt), True, ' TODO : Add test name');
    is-deeply(?$p."$opt"(), True, ' TODO : Add test name');
    is-deeply($p."$opt"(0), False, ' TODO : Add test name');
    is-deeply($p."$opt"(), False, ' TODO : Add test name');
    is-deeply($p."$opt"(1), True, ' TODO : Add test name');

  }
}

{
  my %opts = (map { $_ => False }, @all);
  my $p = LibXML.new: |%opts;
  for @all -> $opt {
    is-deeply($p.get-option($opt), False, ' TODO : Add test name');
    is-deeply($p."$opt"(), False, ' TODO : Add test name');
  }
}

{
     my %opts = (map { $_ => True }, @all);
    my $p = LibXML.new: |%opts;
    for @all -> $opt {
        is-deeply(?$p.get-option($opt), True, ' TODO : Add test name');
        is-deeply(?$p."$opt"(), True, ' TODO : Add test name');
    }
}

