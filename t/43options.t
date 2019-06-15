use Test;
plan 290;

use LibXML;

# TEST:$all=23
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
  no_network
  clean_namespaces
  no_cdata
  no_xinclude_nodes
  old10
  no_base_fix
  huge
  oldsax
  line_numbers
  URI
  base_uri
  gdome
>;

# TEST:$old=8
my %old = map { $_=> True }, qw<
recover
pedantic_parser
line_numbers
load_ext_dtd
complete_attributes
expand_xinclude
clean_namespaces
no_network
>;


{
  my $p = LibXML.new();
  for @all -> $opt {
    my $expected = ? ($opt ~~ 'load_ext_dtd');
    # TEST*$all
    is(? $p.get-option($opt), $expected, "Testing option $opt");
  }
  # TEST
  ok(! $p.option-exists('foo'), ' TODO : Add test name');

  # TEST
  is-deeply( $p.keep-blanks(), True, ' TODO : Add test name' );
  # TEST
  is-deeply( $p.set-option(no_blanks => 1), True, 'Get no_blanks');
  # TEST
  ok( ! $p.keep-blanks(), 'Get keep-blanks' );
  # TEST
  is-deeply( $p.keep-blanks(1), True, 'Set keep-blanks to True' );
  # TEST
  ok( ! $p.get-option('no_blanks'), ' TODO : Add test name' );

}; skip "todo - port remaining tests", 261;
=begin TODO
  
  # TEST
  ok( ! $p.recover_silently(), ' TODO : Add test name' );
  $p.set-option(recover => 1);

  # TEST
  is-deeply( $p.recover_silently(), False, ' TODO : Add test name' );
  $p.set-option(recover => 2);
  # TEST
  is-deeply( $p.recover_silently(), True, ' TODO : Add test name' );
  # TEST
  is-deeply( $p.recover_silently(0), False, ' TODO : Add test name' );
  # TEST
  is-deeply( $p.get-option('recover'), False, ' TODO : Add test name' );
  # TEST
  is-deeply( $p.recover_silently(1), True, ' TODO : Add test name' );
  # TEST
  ok( $p.get-option('recover') == 2, ' TODO : Add test name' );

  # TEST
  is-deeply( $p.expand_entities(), True, ' TODO : Add test name' );
  # TEST
  is-deeply( $p.load_ext_dtd(), True, ' TODO : Add test name' );
  $p.load_ext_dtd(0);
  # TEST
  is-deeply( $p.load_ext_dtd(), False, ' TODO : Add test name' );
  $p.expand_entities(0);
  # TEST
  is-deeply( $p.expand_entities(), False, ' TODO : Add test name' );
  $p.expand_entities(1);
  # TEST
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
        no_network      => 1,
        expand_xinclude => 0,
    );
    my $XML_DOC = $parser.load_xml( string => $XML, );

    # TEST
    ok($XML_DOC.Str().contains($sys_line),
        "expand_entities is preserved after _clone()/etc."
    );
}

{
  my $p = LibXML.new(map { $_=> True }, @all);
  for @all -> $opt {
    # TEST*$all
    is-deeply($p.get-option($opt), True, ' TODO : Add test name');
    # TEST*$old
    if (%old{$opt})
    {
        is-deeply($p.$opt(), True, ' TODO : Add test name')
    }
  }

  for @all -> $opt {
    # TEST*$all
    ok($p.option-exists($opt), ' TODO : Add test name');
    # TEST*$all
    is-deeply($p.set-option($opt,0), False, ' TODO : Add test name');
    # TEST*$all
    is-deeply($p.get-option($opt), False, ' TODO : Add test name');
    # TEST*$all
    is-deeply($p.set-option($opt,1), True, ' TODO : Add test name');
    # TEST*$all
    is-deeply($p.get-option($opt), True, ' TODO : Add test name');
    if (%old{$opt}) {
      # TEST*$old
      is-deeply($p.$opt(), True, ' TODO : Add test name');
      # TEST*$old
      is-deeply($p.$opt(0), False, ' TODO : Add test name');
      # TEST*$old
      is-deeply($p.$opt(), False, ' TODO : Add test name');
      # TEST*$old
      is-deeply($p.$opt(1), True, ' TODO : Add test name');
    }

  }
}

{
  my $p = LibXML.new(map { $_=> False }, @all);
  for @all -> $opt {
    # TEST*$all
    is-deeply($p.get-option($opt), False, ' TODO : Add test name');
    # TEST*$old
    if (%old{$opt})
    {
        is-deeply($p.$opt(), False, ' TODO : Add test name');
    }
  }
}

{
    my $p = LibXML.new({map { $_=> True }, @all});
    for my @all -> $opt {
        # TEST*$all
        is-deeply($p.get-option($opt), True, ' TODO : Add test name');
        # TEST*$old
        if (%old{$opt})
        {
            is-deeply($p.$opt(), True, ' TODO : Add test name');
        }
    }
}

=end TODO
