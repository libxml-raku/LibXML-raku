class LibXML::SAX::Builder {
    use LibXML::Native;
    use NativeCall;

    my role is-sax-cb {
    }
    multi trait_mod:<is>(Method $m, :sax-cb($)!) is export(:sax-cb) {
        $m does is-sax-cb;
    }

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

    method !build(Any:D $obj, $handler, %dispatches) {
        my Bool %seen;
        for $obj.^methods.grep(* ~~ is-sax-cb) -> &meth {
            my $name = &meth.name;
            with %dispatches{$name} -> &dispatch {
                %seen{$name} = True;
                $handler."$name"() = dispatch($obj, &meth);
            }
            else {
                my $known = %dispatches.keys.sort.join: ' ';
                die "unknown SAX method $name. expected: $known";
            }
        }
        warn "'startElement' and 'startElementNs' callbacks are mutually exclusive"
            if %seen<startElement> && %seen<startElementNs>;
        warn "'endElement' and 'endElementNs' callbacks are mutually exclusive"
            if %seen<endElement> && %seen<endElementNs>;
        $handler;
    }

    method build-sax($obj, xmlSAXHandler :$sax = xmlSAXHandler.new) {
        $sax.init;
        self!build($obj, $sax, %SAXHandlerDispatch);
    }

    method build-locator($obj, xmlSAXLocator :$locator = xmlSAXLocator.new) {
        self!build($obj, $locator, %SAXLocatorDispatch);
    }
}
