use Test;
use LibXML::RegExp;

plan 14;


{
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my $re = LibXML::RegExp.new(:$regexp);

    # TEST
    ok( $re, 'Regex object was initted.');
    # TEST
    ok( ! $re.matches('00'), 'Does not match 00' );
    # TEST
    ok( ! $re.matches('00-'), 'Does not match 00-' );
    # TEST
    ok( $re.matches('12345'), 'Matches 12345' );
    # TEST
    ok( !$re.matches('123456'), 'Does not match 123456' );

    # TEST
    ok( $re.matches('12345-1234'), 'Matches 12345-1234');
    # TEST
    ok( ! $re.matches(' 12345-1234'), 'Does not match leading space');
    # TEST
    ok( ! $re.matches(' 12345-12345'), 'Leading space No. 2' );
    # TEST
    ok( ! $re.matches('12345-1234 '), 'Trailing space' );

    # TEST
    ok( $re.isDeterministic, 'Regex is deterministic' );
}

{
    my $nondet_regex = '(bc)|(bd)';
    my $nondet_re = LibXML::RegExp.new(regexp => $nondet_regex);

    # TEST
    ok( $nondet_re, 'Non deterministic re was initted' );
    # TEST
    ok( ! $nondet_re.isDeterministic, 'It is not deterministic' );
}

# silence this test
my $errors;
LibXML::Native.GenericErrorFunc = -> $ctx, $fmt, |c { $errors++ }

{
    my $bad_regex = '[0-9]{5}(-[0-9]{4}?';
    dies-ok { LibXML::RegExp.new(regexp => $bad_regex); },  'An exception was thrown on bad regex';
    ok $errors, 'error handler called';
}
