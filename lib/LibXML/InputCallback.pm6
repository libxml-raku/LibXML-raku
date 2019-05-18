use v6;

unit class LibXML::InputCallback;

my class CallbackGroup {
    has &.match is required;
    has &.open  is required;
    has &.read  is required;
    has &.close is required;
}

my class Context {
    use NativeCall;

    has CallbackGroup $.cb is required;

    my class Handle {
        has Pointer $.addr;
        method addr { with self { $!addr } else { 0 } }
        has $.fh is rw;
        has Blob $.buf is rw;
        sub malloc(size_t --> Pointer) is native {*}
        sub free(Pointer:D) is native {*}
        submethod TWEAK   { $!addr = malloc(1); }
        submethod DESTROY { free($_) with $!addr }
    }
    has Handle %.handles{UInt};

    sub memcpy(CArray[uint8], CArray[uint8], size_t --> CArray[uint8]) is native {*}

    method match {
        -> Str:D $file --> Int {
            CATCH { default { warn $_; return False; } }
            + $!cb.match.($file).so;
        }
    }

    method open {
        -> Str:D $file --> Pointer {
            my Handle $handle;
            CATCH { default { warn $_; return Pointer; } }
            my $fh = $!cb.open.($file);
            with $fh {
                $handle .= new: :$fh;
                %!handles{+$handle.addr} = $handle;
            }

            $handle.addr;
        }
    }

    method read {
        -> Pointer $addr, CArray $out-arr, UInt $bytes --> Int {
            CATCH { default { warn $_; return Pointer; } }
            my Handle $handle = %!handles{+$addr}
                // die "read on unknown handle";
            with $handle.buf // $!cb.read.($handle.fh, $bytes) -> Blob $io-buf {
                my $n-read := $io-buf.bytes;
                if $n-read > $bytes {
                    # read-buffer exceeds output buffer size;
                    # buffer the excess
                    $handle.buf = $io-buf.subbuf($bytes);
                    $io-buf .= subbuf(0, $bytes);
                    $n-read = $bytes;
                }
                else {
                    $handle.buf = Nil;
                }

                my CArray[uint8] $io-arr := nativecast(CArray[uint8], $io-buf);
                memcpy($out-arr, $io-arr, $n-read)
                    if $n-read;

                $n-read;
            }
        }
    }

    method close {
        -> Pointer:D $addr --> Int {
            CATCH { default { warn $_; return -1 } }
            my Handle $handle = %!handles{+$addr}
                // die (+$addr).fmt("read on unopened input callback context: 0x%X");
            $!cb.close.($handle.fh);
            %!handles{+$addr}:delete;

            0;
        }
    }
}

has CallbackGroup @!callbacks;
method callbacks { @!callbacks }

multi method TWEAK( Hash :$callbacks ) {
    @!callbacks = CallbackGroup.new(|$_)
        with $callbacks;
}

multi method register-callbacks( :&match!, :&open!, :&read!, :&close! ) {
    my CallbackGroup $cb .= new: :&match, :&open, :&read, :&close;
    @!callbacks.push: $cb;
}

multi method register-callbacks( &match, &open, &read, &close ) is default {
    $.register-callbacks( :&match, :&open, :&read, :&close );
}

multi method unregister-callbacks( :&match, :&open, :&read, :&close ) is default {
    @!callbacks .= grep: {
        (!&match.defined    || &match === .match)
        && (!&open.defined  || &open  === .open)
        && (!&read.defined  || &read  === .read)
        && (!&close.defined || &close === .close)
    }
}

method make-contexts {
    @!callbacks.map: -> $cb { Context.new: :$cb }
}

