unit role LibXML::_StringyNode;

method nodeValue { ... }
method content {...}

multi method new(Str:D() $content, *%o) {
    self.new(:$content, |%o);
}

multi method new(|c) is default { nextsame }

method data returns Str is rw { $.nodeValue }

# DOM Boot-leather
method substringData(UInt:D $off, UInt:D $len --> Str) { $.substr($off, $len) }
method appendData(Str:D $val --> Str) { $.content ~= $val }
method insertData(UInt:D $pos, Str:D $val) { $.content.substr-rw($pos, 0) = $val; }
method setData(Str:D $val --> Str) { $.content = $val; }
method getData returns Str { $.content; }
multi method replaceData(UInt:D $off, UInt:D $length, Str:D $val --> Str) {
    my $len = $.content.chars;
    if $len > $off {
        $.substr-rw($off, $length) = $val;
    }
    else {
        Str
    }
}

my subset StrOrRegex where Str|Regex;
my subset StrOrCode where Str|Code;
method replaceDataString(StrOrRegex:D $old, StrOrCode:D $new, |c --> Str) {
    $.content = $.content.subst($old, $new, |c);
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
method ast { self.nodeName => self.nodeValue }

