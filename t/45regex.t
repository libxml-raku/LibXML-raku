use v6;
use Test;
use LibXML::RegExp;
use LibXML::Parser::Context;

plan 22;

{
    my $regexp = '[0-9]{5}(-[0-9]{4})?';
    my LibXML::RegExp $re .= new: :$regexp;

    ok $re, 'Regex object was initted.';
    ok ! $re.matches('00'), 'Does not match 00';
    ok ! $re.matches('00-'), 'Does not match 00-';
    ok $re.matches('12345'), 'Matches 12345';
    ok !$re.matches('123456'), 'Does not match 123456';

    ok $re.matches('12345-1234'), 'Matches 12345-1234';
    ok ! $re.matches(' 12345-1234'), 'Does not match leading space';
    ok ! $re.matches(' 12345-12345'), 'Leading space No. 2';
    ok ! $re.matches('12345-1234 '), 'Trailing space';

    ok '12345-1234' ~~ $re, 'ACCEPTS match';
    nok '12345-1234' !~~ $re, 'ACCEPTS match negated';
    ok ' 12345-1234' !~~ $re, 'ACCEPTS non-match negated';
    nok ' 12345-1234' ~~ $re, 'ACCEPTS non-match';
    ok $re ~~ LibXML::RegExp, 'ACCEPTS obj/class match';
    nok $re ~~ LibXML::ErrorHandling, 'ACCEPTS obj/class non-match';
    nok Str ~~ $re, 'ACCEPTS class/obj non-match';
    nok Str ~~ LibXML::RegExp, 'ACCEPTS class/class non-match';
    ok  LibXML::RegExp ~~ LibXML::RegExp, 'ACCEPTS class/class match';

    ok $re.isDeterministic, 'Regex is deterministic';
}

{
    my $nondet_regex = '(bc)|(bd)';
    my LibXML::RegExp $nondet_re .= new(regexp => $nondet_regex);

    ok $nondet_re, 'Non deterministic re was initted';
    ok ! $nondet_re.isDeterministic, 'It is not deterministic';
}

# silence this test
my $errors;
LibXML::Parser::Context.SetGenericErrorFunc(-> $fmt, |c { $errors++ })
    unless LibXML::Config.version >= v2.13.00;

{
    my $bad_regex = '[0-9]{5}(-[0-9]{4}?';
    dies-ok { LibXML::RegExp.new(regexp => $bad_regex); },  'An exception was thrown on bad regex';
}
