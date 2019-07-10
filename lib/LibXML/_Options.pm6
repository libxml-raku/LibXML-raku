unit role LibXML::_Options[%OPTS];

method get-flag(UInt $flags, Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    with %OPTS{$k} {
        ($flags +& $_) == $_
    }
    else {
        with %OPTS{'no-' ~ $k} {
            # mask - negated
            ! ($flags +& $_);
        }
        else {
            fail "unknown parser flag: $k";
        }
    }
}

method set-flag(UInt $flags is rw, Str:D $k is copy, Bool() $v) {
    $k .= subst("_", "-", :g);
    $flags //= 0;
    with %OPTS{$k} {
        # mask
        if $v {
            $flags +|= $_;
        }
        else {
            $flags = $flags +& (0xffffffff +^ $_)
            if $flags +& $_;
        }
    }
    else {
        with %OPTS{'no-' ~ $k} {
            # mask - negated
            $.set-flag($flags, 'no-' ~ $k, ! $v);
        }
        else {
            fail "unknown parser flag: $k";
        }
    }
    $v;
}

method set-flags($flags is rw, *%opts) {
    $flags //= 0;
    for %opts.pairs.sort {
        self.set-flag($flags, .key, .value);
    }
    $flags;
}

method option-exists(Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    (%OPTS{$k} // %OPTS{'no-' ~ $k}).defined;
}

method get-option(Str:D $k) is default {
    if self.can($k) {
        self."$k"();
    }
    else {
        $.get-flag($.flags, $k);
    }
}
multi method set-option(Str:D $k, $_) is default {
    if self.can($k) {
        self."$k"() = $_;
    }
    else {
        $.set-flag($.flags, $k, $_);
    }
}
multi method set-option(*%opt) { $.set-options(|%opt); }
method set-options(*%opt) {
    my $rv := $.set-option(.key, .value) for %opt.sort;
    $rv;
}

multi method option(Str:D $key) is rw {
    Proxy.new(
        FETCH => { $.get-option($key) },
        STORE => -> $, Bool() $val {
            $.set-option($key, $val);
        });
}

multi method option(Str:D $key, Bool() $val) {
    $.set-option($key, $val);
}
