class LibXML::SAX::Builder {
    use LibXML::Native;
    use NativeCall;

    sub atts-Hash(CArray[Str] $atts) {
        my %atts;
        with $atts {
            my int $i = 0;
            loop {
                my $key = .[$i++] // last;
                my $val = .[$i++] // last;
                %atts{$key} = $val;
            }
        }
        %atts
    }

    my %Dispatch = %(
        startElement =>
            -> $obj, &method {
                -> parserCtxt $ctx, Str $name, CArray[Str] $raw-atts {
                    my %atts := atts-Hash($raw-atts);
                    method($obj, $name, :$ctx, :%atts, :$raw-atts);
                }
            },
        'endElement'|'getEntity' =>
            -> $obj, &method {
                -> parserCtxt $ctx, Str $name {
                    method($obj, $name, :$ctx);
                }
            },
        characters =>
            -> $obj, &method {
                -> parserCtxt $ctx, CArray[byte] $chars, int32 $len {
                    # ensure null termination
                    sub memcpy(Blob $dest, CArray $chars, size_t $n) is native {*};
                    my buf8 $char-buf .= new;
                    $char-buf[$len-1] = 0
                        if $len > 0;
                    memcpy($char-buf, $chars, $len);
                    method($obj, $char-buf.decode, :$ctx);
                }
            },
    );

    method build(:$sax = xmlSAXHandler.new) {
        my LibXML::SAX::Builder $obj = self;
        $_ .= new without $obj;

        for %Dispatch.pairs.sort {
            my $name := .key;
            with self.can($name) -> $methods {
                my &dispatch := .value;
                $sax."$name"() = dispatch($obj, $methods[0])
                    if +$methods;
            }
        }
        $sax;
    }

}
