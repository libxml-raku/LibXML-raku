unit class LibXML::Pattern;

use LibXML::Enums;
use LibXML::Native;
use LibXML::Node;
use LibXML::_Options;
use NativeCall;

enum Flags (
    PAT_FROM_ROOT => 1 +< 8,
    PAT_FROM_CUR  => 1 +< 9
);

also does LibXML::_Options[
    %(
        :default(XML_PATTERN_DEFAULT),
        :xpath(XML_PATTERN_XPATH),
        :xssel(XML_PATTERN_XSSEL),
        :xsfield(XML_PATTERN_XSFIELD),
        :from-root(PAT_FROM_ROOT),
        :from-cur(PAT_FROM_CUR),
    )
];

has xmlPattern $!native;
method native { $!native }
has UInt $.flags;

submethod TWEAK(Str:D :$pattern!, :%ns, *%opts) {
    self.set-flags($!flags, %opts);
    my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
    $!native .= new: :$pattern, :$!flags, :$ns;
}

submethod DESTROY {
    .Free with $!native;
}

method compile(Str:D $pattern, |c) {
    self.new: :$pattern, |c;
}

method !try-bool(Str:D $op, |c) {
    my $rv := $!native."$op"(|c);
    fail X::LibXML::Reader::OpFail.new(:$op)
        if $rv < 0;
    $rv > 0;
}

multi method matchesNode(LibXML::Node $node) {
    self!try-bool('Match', $node.native);
}

multi method matchesNode(domNode $node) {
    self!try-bool('Match', $node);
}

method get-option(Str:D $key) { $.get-flag($!flags, $key); }
method set-option(Str:D $key, Bool() $_) { $.set-flag($!flags, $key, $_); }
