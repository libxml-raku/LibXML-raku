#| This role models the W3C DOM CharacterData abstract class
unit role LibXML::_CharacterData;

use LibXML::Raw;
use LibXML::Node;

multi method new(LibXML::Node :doc($owner), Str() :$content!, *%c) {
    my xmlDoc $doc = .raw with $owner;
    my anyNode:D $raw = self.raw.new: :$content, :$doc;
    self.box: $raw, |%c;
}
multi method new(Str:D() $content, *%c) {
    self.new(:$content, |%c);
}

method data {...}
method cloneNode {...}
method !substr(|c) {$.data.substr(|c)}
method !substr-rw(|c) is rw {$.data.substr-rw(|c)}

method length { $.data.chars }

# DOM Boot-leather
method substringData(UInt:D $off, UInt:D $len --> Str) { self!substr($off, $len) }
method appendData(Str:D $val --> Str) { self!substr-rw(*-0, 0) = $val }
method insertData(UInt:D $pos, Str:D $val) { self!substr-rw($pos, 0) = $val; }
method setData(Str:D $val --> Str) { self!substr-rw(0, *) = $val; }
method getData returns Str { $.data }
multi method replaceData(UInt:D $off, UInt:D $length, Str:D $val --> Str) {
    my $len = $.length;
    if $len > $off {
        self!substr-rw($off, $length) = $val;
    }
    else {
        Str
    }
}

method splitText(UInt $off) {
    my $len = $.length;
    my $new = self.cloneNode;
    with self.parent {
        .insertAfter($new, self);
    }
    if $off >= $len {
        $new.setData('');
    }
    else {
        self.replaceData($off, $len - $off, '');
        $new.replaceData(0, $off, '');
    }
    $new;
}

my subset StrOrRegex where Str|Regex;
my subset StrOrCode where Str|Code;
method replaceDataString(StrOrRegex:D $old, StrOrCode:D $new, |c --> Str) {
    $.data .= subst($old, $new, |c);
}
method deleteDataString(StrOrRegex:D $old, |c --> Str) {
    $.replaceDataString($old, '', |c);
}
multi method replaceData(StrOrRegex:D $old, StrOrCode:D $new, |c  --> Str) {
    $.replaceDataString($old, $new, |c);
}
multi method deleteData(UInt:D $off, UInt:D $length --> Str) {
    $.replaceData($off, $length, '');
}
multi method deleteData(StrOrRegex $old, |c --> Str) {
    $.replaceData($old, '', |c);
}

