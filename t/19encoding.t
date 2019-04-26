use v6;
use Test;

INIT {
    my $tests        = 1;
    my $basics       = 0;
    my $magic        = 6;
    my $step = $basics + $magic;

    $tests += $step;

    with %*ENV<TEST_LANGUAGES> {
      when 'all' {
          $tests += 2 * $step;
      }
      when "EUC-JP"|"KOI8-R" {
        $tests += $step;
      }
    }
    plan $tests;
}

use LibXML;

# TEST
ok(1, 'Loading');

my $p = LibXML.new();

my $tstr_utf8       = 'test';
my $tstr_iso_latin1 = "täst";

my $domstr-lat1 = q{<?xml version="1.0" encoding="iso-8859-1"?>
<täst>täst</täst>
};

my $domstr-utf8 = q{<?xml version="1.0" encoding="UTF-8"?>
<täst>täst</täst>
};

{
    # magic encoding tests

    my $dom_latin1 = LibXML::Document.new(:enc<iso-8859-1>);
    my $elemlat1   = $dom_latin1.createElement( $tstr_iso_latin1 );

    $dom_latin1.setDocumentElement( $elemlat1 );

    # TEST
    is( $elemlat1.Str,
        "<$tstr_iso_latin1/>", ' TODO : Add test name');
    # TEST
    is( $elemlat1.Str, "<$tstr_iso_latin1/>", ' TODO : Add test name');

    my $elemlat2   = $dom_latin1.createElement( "Öl" );
    # TEST
    is( $elemlat2.Str, "<Öl/>", ' TODO : Add test name');

    $elemlat1.appendText( $tstr_iso_latin1 );

    # TEST
    is( $elemlat1.string-value,
        $tstr_iso_latin1, ' TODO : Add test name');
    # TEST
    is( $elemlat1.string-value(), $tstr_iso_latin1, ' TODO : Add test name');

    # TEST
    is( $dom_latin1.Str(), $domstr-utf8, ' TODO : Add test name' );

}

exit(0) without %*ENV<TEST_LANGUAGES>;

if %*ENV<TEST_LANGUAGES> ~~ 'all'|'EUC-JP' {
    # japanese encoding (EUC-JP)

    my $tstr_euc_jp     = '生麦生米生卵';
    my $domstr-jp = q{<?xml version="1.0" encoding="EUC-JP"?>
<生麦生米生卵>生麦生米生卵</生麦生米生卵>
};

    {
        # this EUC-JP example uses a subset of UTF-8
        my $domstr-utf8 =  $domstr-jp.subst('EUC-JP', 'UTF-8');
        my $dom_euc_jp = LibXML::Document.new( :enc<EUC-JP>);
        my $elemjp = $dom_euc_jp.createElement( $tstr_euc_jp );


        # TEST

        is( $elemjp.nodeName,
            $tstr_euc_jp, ' TODO : Add test name' );
        # TEST
        is( $elemjp.Str,
            "<$tstr_euc_jp/>", ' TODO : Add test name');
        # TEST
        is( $elemjp.Str(), "<$tstr_euc_jp/>", ' TODO : Add test name');

        $dom_euc_jp.setDocumentElement( $elemjp );
        $elemjp.appendText( $tstr_euc_jp );

        # TEST

        is( $elemjp.string-value,
            $tstr_euc_jp, ' TODO : Add test name');
        # TEST
        is( $elemjp.string-value(), $tstr_euc_jp, ' TODO : Add test name');

        # TEST

        is( $dom_euc_jp.Str(), $domstr-utf8, ' TODO : Add test name' );
    }

}

if ( %*ENV<TEST_LANGUAGES> ~~ 'all'|'KOI8-R' ) {
    # cyrillic encoding (KOI8-R)

    my $tstr_koi8r       = 'проба';
    my $domstr-koi = q{<?xml version="1.0" encoding="KOI8-R"?>
<проба>проба</проба>
};
    my $domstr-utf8 =  $domstr-koi.subst('KOI8-R', 'UTF-8');

    {
        my ($dom_koi8, $elemkoi8);

        $dom_koi8 = LibXML::Document.new(:enc<KOI8-R>);
        $elemkoi8 = $dom_koi8.createElement( $tstr_koi8r );

        # TEST

        is( $elemkoi8.nodeName,
            $tstr_koi8r, ' TODO : Add test name' );

        # TEST

        is( $elemkoi8.Str,
            "<$tstr_koi8r/>", ' TODO : Add test name');
        # TEST
        is( $elemkoi8.Str, "<$tstr_koi8r/>", ' TODO : Add test name');

        $elemkoi8.appendText( $tstr_koi8r );

        # TEST

        is( $elemkoi8.string-value,
            $tstr_koi8r, ' TODO : Add test name');
        # TEST
        is( $elemkoi8.string-value(),
            $tstr_koi8r, ' TODO : Add test name');
        $dom_koi8.setDocumentElement( $elemkoi8 );

        # TEST

        is( $dom_koi8.Str(),
            $domstr-utf8, ' TODO : Add test name' );

    }
}
