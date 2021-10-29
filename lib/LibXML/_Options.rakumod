unit role LibXML::_Options[%OPTS];

multi sub neg($_ where .starts-with('no-')) { .substr(3) }
multi sub neg($_) { 'no-' ~ $_ }

method get-flag(UInt $flags, Str:D $k is copy) {
    $k .= subst("_", "-", :g);
    with %OPTS{$k} {
        ($flags +& $_) == $_
            unless $_ ~~ Bool;
    }
    else {
        with %OPTS{neg($k)} {
            # mask - negated
            ! (($flags +& $_) == $_)
                unless $_ ~~ Bool;
        }
        else {
            warn "unknown parser flag: $k";
            Bool;
        }
    }
}

multi method set-flag(UInt $flags is rw, 'flags', UInt $v, $?) {
    $flags +|= $v;
}
multi method set-flag(UInt $flags is rw, Str:D $k is copy, Bool() $v, Bool $lax?) {
    $k .= subst("_", "-", :g);
    $flags //= 0;
    with %OPTS{$k} {
        # mask
        when Bool { }
        when $v {
            $flags +|= $_;
        }
        default {
            $flags = $flags +& (0xffffffff +^ $_)
            if $flags +& $_;
        }
    }
    else {
        my $kn := neg($k);
        with %OPTS{$kn} {
            # mask - negated
            $.set-flag($flags, $kn, ! $v);
        }
        else {
            warn "unknown parser flag: $k"
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

method get-option(Str:D $k is copy) {
    my $neg := ? $k.starts-with('no-');
    $k .= substr(3) if $neg;
    my $rv := self.can($k)
        ?? self."$k"()
        !! $.get-flag($.flags, $k);
    $neg ?? ! $rv !! $rv;
}
multi method set-option(Str:D $k is copy, $v is copy) is default {
    my $neg := ? $k.starts-with('no-');
    if $neg {
        $k .= substr(3);
        $v = ! $v;
    }
    my $rv := self.can($k)
       ?? (self."$k"() = $v)
       !! $.set-flag($.flags, $k, $v);
    $neg ?? ! $rv !! $rv;
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
