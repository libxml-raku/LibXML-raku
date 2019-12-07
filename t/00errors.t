use v6;
use Test;
plan 4;
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
