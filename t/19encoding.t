use v6;
use Test;
plan 3;
use LibXML;
use LibXML::Document;
use LibXML::Element;
use LibXML::Config;

my \config =  LibXML::Config;

my LibXML $p .= new();

my $tstr_utf8       = 'test';
my $tstr_iso_latin1 = "täst";

my $domstr-lat1 = q{<?xml version="1.0" encoding="iso-8859-1"?>
<täst>täst</täst>
};

my $domstr-utf8 = q{<?xml version="1.0" encoding="UTF-8"?>
<täst>täst</täst>
};

subtest 'latin-1', {
    # magic encoding tests

    my LibXML::Document $dom_latin1 .= new(:enc<iso-8859-1>);
    my $elemlat1   = $dom_latin1.createElement( $tstr_iso_latin1 );

    $dom_latin1.setDocumentElement( $elemlat1 );

    is $elemlat1.Str, "<$tstr_iso_latin1/>";
    is $elemlat1.Str, "<$tstr_iso_latin1/>";

    my $elemlat2   = $dom_latin1.createElement( "Öl" );
    is $elemlat2.Str, "<Öl/>";

    $elemlat1.appendText( $tstr_iso_latin1 );

    is $elemlat1.string-value,  $tstr_iso_latin1;
    is $elemlat1.string-value(), $tstr_iso_latin1;

    is $dom_latin1.Str(), $domstr-utf8;

}

unless config.have-iconv {
    skip-rest "this libxml library was built without iconv for encoding";
    exit 0;
}

subtest 'japanese encoding (EUC-JP)', {
    my $tstr_euc_jp     = '生麦生米生卵';
    my $domstr-jp = q{<?xml version="1.0" encoding="EUC-JP"?>
<生麦生米生卵>生麦生米生卵</生麦生米生卵>
};

    # this EUC-JP example uses a subset of UTF-8
    my $domstr-utf8 =  $domstr-jp.subst('EUC-JP', 'UTF-8');
    my LibXML::Document $dom_euc_jp .= new( :enc<EUC-JP>);
    my $elemjp = $dom_euc_jp.createElement( $tstr_euc_jp );

    is $elemjp.nodeName, $tstr_euc_jp;
    is $elemjp.Str,  "<$tstr_euc_jp/>";
    is $elemjp.Str(), "<$tstr_euc_jp/>";

    $dom_euc_jp.setDocumentElement( $elemjp );
    $elemjp.appendText( $tstr_euc_jp );

    is $elemjp.string-value, $tstr_euc_jp;
    is $elemjp.string-value(), $tstr_euc_jp;

    is $dom_euc_jp.Str(), $domstr-utf8;
}

subtest 'cyrillic encoding (KOI8-R)', {
    my $tstr_koi8r       = 'проба';
    my $domstr-koi = q{<?xml version="1.0" encoding="KOI8-R"?>
<проба>проба</проба>
};
    my $domstr-utf8 =  $domstr-koi.subst('KOI8-R', 'UTF-8');

    my LibXML::Document $dom_koi8 .= new(:enc<KOI8-R>);
    my LibXML::Element $elemkoi8 = $dom_koi8.createElement( $tstr_koi8r );

    is $elemkoi8.nodeName, $tstr_koi8r;

    is $elemkoi8.Str, "<$tstr_koi8r/>";
    is $elemkoi8.Str, "<$tstr_koi8r/>";

    $elemkoi8.appendText( $tstr_koi8r );

    is $elemkoi8.string-value, $tstr_koi8r;
    is $elemkoi8.string-value(), $tstr_koi8r;
    $dom_koi8.setDocumentElement( $elemkoi8 );

    is $dom_koi8.Str(), $domstr-utf8;
}
