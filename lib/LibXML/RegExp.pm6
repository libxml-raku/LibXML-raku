unit class LibXML::RegExp;

use LibXML::Enums;
use LibXML::Native;
use LibXML::Node;
use NativeCall;

enum Flags (
    PAT_FROM_ROOT => 1 +< 8,
    PAT_FROM_CUR  => 1 +< 9
);

has xmlRegexp $!native;
method native { $!native }
has UInt $.flags;

submethod TWEAK(Str:D :$regexp!) {
    $!native .= new(:$regexp)
       // die "failed to compile regexp";
}

submethod DESTROY {
    .Free with $!native;
}

method compile(Str:D $regexp, |c) {
    self.new: :$regexp, |c;
}

method !try-bool(Str:D $op, |c) {
    my $rv := $!native."$op"(|c);
    fail X::LibXML::Reader::OpFail.new(:$op)
        if $rv < 0;
    $rv > 0;
}

method matches(Str:D $content) {
    self!try-bool('Match', $content);
}

method isDeterministic {
    self!try-bool('IsDeterministic');
}
