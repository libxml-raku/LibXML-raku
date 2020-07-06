use v6;
use Test;
use LibXML::XPath::Context;

my $errors;
LibXML::XPath::Context.SetGenericErrorFunc(-> |c { $errors++ });
plan 5;
{
    use LibXML::Pattern;
    my LibXML::Pattern $patt;

    lives-ok {$patt.new(:pattern('a'))};
    throws-like { $patt.new(:pattern('a[zz')) }, X::LibXML::OpFail, :message('XML Pattern Compile operation failed');
}

{
    use LibXML::RegExp;
    my LibXML::RegExp $regexp;

    lives-ok {$regexp.new(:regexp('a'))};
    throws-like { $regexp.new(:regexp('a[zz')) }, X::LibXML::OpFail, :message('XML RegExp Compile operation failed');
}

ok $errors, 'errors caught';
