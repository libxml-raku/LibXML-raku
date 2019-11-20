use v6;
use Test;
use LibXML::RegExp;
use LibXML::ErrorHandling;

plan 14;


{
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my $re = LibXML::RegExp.new(:$regexp);

    ok( $re, 'Regex object was initted.');
    ok( ! $re.matches('00'), 'Does not match 00' );
    ok( ! $re.matches('00-'), 'Does not match 00-' );
    ok( $re.matches('12345'), 'Matches 12345' );
    ok( !$re.matches('123456'), 'Does not match 123456' );

    ok( $re.matches('12345-1234'), 'Matches 12345-1234');
    ok( ! $re.matches(' 12345-1234'), 'Does not match leading space');
    ok( ! $re.matches(' 12345-12345'), 'Leading space No. 2' );
    ok( ! $re.matches('12345-1234 '), 'Trailing space' );

    ok( $re.isDeterministic, 'Regex is deterministic' );
}

{
    my $nondet_regex = '(bc)|(bd)';
    my $nondet_re = LibXML::RegExp.new(regexp => $nondet_regex);

    ok( $nondet_re, 'Non deterministic re was initted' );
    ok( ! $nondet_re.isDeterministic, 'It is not deterministic' );
}

# silence this test
my $errors;
LibXML::ErrorHandling.SetGenericErrorFunc(-> $fmt, |c { $errors++ });

{
    my $bad_regex = '[0-9]{5}(-[0-9]{4}?';
    dies-ok { LibXML::RegExp.new(regexp => $bad_regex); },  'An exception was thrown on bad regex';
    ok $errors, 'error handler called';
}
