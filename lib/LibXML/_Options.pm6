unit role LibXML::_Options[%FLAGS];

method get-flag(UInt $flags, Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    with %FLAGS{'no-' ~ $k} {
           ! ($flags +& $_)
    }
    else {
        with %FLAGS{$k} {
            ? ($flags +& $_)
        }
        else {
            fail "unknown parser flag: $k";
        }
    }
}

method set-flag(UInt $flags is rw, Str:D $k is copy, Bool() $v) {
    $k .= subst("_", "-", :g);
    $flags //= 0;
    with %FLAGS{'no-' ~ $k} {
        $.set-flag($flags, 'no-' ~ $k, ! $v);
    }
    else {
        with %FLAGS{$k} {
            if $v {
                $flags += $_
                    unless $flags +& $_;
            }
            else {
                $flags -= $_
                    if $flags +& $_;
            }
        }
        else {
            fail "unknown parser flag: $k";
        }
    }
    $v;
}

method set-flags($flags is rw, %opts) {
    $flags //= 0;
    for %opts.pairs.sort {
        self.set-flag($flags, .key, .value);
    }
}

method option-exists(Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    (%FLAGS{$k} // %FLAGS{'no-' ~ $k}).defined;
}

method get-option($) {...}
method set-option($,$) {...}

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
