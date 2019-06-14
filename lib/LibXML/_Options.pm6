unit role LibXML::_Options[%FLAGS];

method get-flag(UInt $flags, Str:D $k) {
    with %FLAGS{'no-' ~ $k} {
           ! ($flags +& $_)
    }
    else {
        with %FLAGS{$k} {
            ? ($flags +& $_)
        }
        else {
            fail "unknown parser flag: $_";
        }
    }
}

method set-flag(UInt $flags is rw, Str:D $k, Bool() $v) {
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

method is-option(Str:D $key) {
    (%FLAGS{$key} // %FLAGS{'no-' ~ $key}).defined;
}

method get-option($) {...}
method set-option($,$) {...}

method option(Str:D $key) is rw {
    Proxy.new(
        FETCH => { $.get-option($key) },
        STORE => -> $, Bool() $_ {
            $.set-option($key, $_);
        });
}

