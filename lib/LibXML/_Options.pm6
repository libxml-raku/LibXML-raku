unit role LibXML::_Options[%OPTS];

sub neg($k) { $k.starts-with('no-') ?? $k.substr(3) !! 'no-' ~ $k; }

method get-flag(UInt $flags, Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    with %OPTS{$k} {
        ($flags +& $_) == $_
    }
    else {
        with %OPTS{neg($k)} {
            # mask - negated
            ! (($flags +& $_) == $_);
        }
        else {
            fail "unknown parser flag: $k";
        }
    }
}

method set-flag(UInt $flags is rw, Str:D $k is copy, Bool() $v, Bool $lax?) {
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
        my $k1 = neg($k);
        with %OPTS{$k1} {
            # mask - negated
            $.set-flag($flags, $k1, ! $v);
        }
        else {
            fail "unknown parser flag: $k"
                unless $lax;
        }
    }
    $v;
}

method set-flags($flags is rw, Bool :$lax, *%opts) {
    $flags //= 0;
    for %opts.pairs.sort {
        self.set-flag($flags, .key, .value, $lax);
    }
    $flags;
}

method option-exists(Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    (%OPTS{$k} // %OPTS{neg($k)}).defined;
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

method options {
    my %opts;
    with self {
        for %OPTS.keys.sort -> $k {
            %opts{$k} = $_
                with .get-option($k);
        }
    }
    %opts;
}
