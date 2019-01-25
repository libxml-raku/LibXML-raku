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

    my %SAXLocatorDispatch = %(
        'getPublicId'|'getSystemId' =>
            sub ($obj, &method) {
                sub (--> Str) {
                    method($obj);
                }
            },
        'getLineNumber'|'getColumnNumber' =>
            sub ($obj, &method) {
                sub (--> UInt) {
                    method($obj);
                }
            },
    );

    my %SAXHandlerDispatch = %(
        'startElement' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name, CArray[Str] $raw-atts) {
                    my %atts := atts-Hash($raw-atts);
                    method($obj, $name, :$ctx, :%atts, :$raw-atts);
                }
            },
        'endElement'|'getEntity' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name) {
                    method($obj, $name, :$ctx);
                }
            },
        'characters' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, CArray[byte] $chars, int32 $len) {
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

    method !build(Any:D $obj, $handler, %dispatch) {
        for %dispatch.pairs.sort {
            my $name     := .key;
            my &dispatch := .value;

            with $obj.can($name) -> $methods {
                $handler."$name"() = dispatch($obj, $methods[0])
                    if +$methods;
            }
            else {
                warn "no handler method '$name'";
            }
        }
        $handler;
    }

    method build-sax($obj) {
        my xmlSAXHandler $sax .= new;
        self!build($obj, $sax, %SAXHandlerDispatch);
    }

    method build-locator($obj, xmlSAXLocator $locator) {
        self!build($obj, $locator, %SAXLocatorDispatch);
    }
}
