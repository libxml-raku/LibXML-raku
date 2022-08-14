use LibXML;
use Test;
use JSON::Fast;

plan 2;

my %META6 = from-json "META6.json".IO.slurp;
my Version:D() $ver = LibXML.^ver;

subtest 'LibXML.^ver', {
    ok $ver, 'is Trueish';
    my @parts = $ver.Str.split: '.';

    is +@parts, 3, 'is semantic (X.Y.Z)';
    is-deeply ~$ver, %META6<version>, "consistant with META6<version>"
        or diag "Mismatch between LibXML.^ver({LibXML.^ver.raku}) and META6<version>({%META6<version>.raku})"
}

subtest 'LibXML.^api', {
    my Version:D() $api = LibXML.^api;
    ok $api, 'is Trueish';
    my @parts = $api.Str.split: '.';

    ok 2 <= +@parts <= 3, 'is of form X.Y[.Z]';
    my $ver-base = Version.new('v' ~ $ver.parts[0..*-2].join('.')~'.0');
    ok $ver-base <= $api <= $ver, "api within range ($ver-base <= $api <= $ver)";

    is-deeply ~$api, %META6<api>, "consistant with META6<api>"
        or diag "Mismatch between LibXML.^api({LibXML.^api.raku}) and META6<api>({%META6<api>.raku})";
}
