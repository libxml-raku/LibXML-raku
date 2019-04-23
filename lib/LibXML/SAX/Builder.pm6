class LibXML::SAX::Builder {
    use LibXML::Native;
    use NativeCall;

    my role is-sax-cb {
    }
    multi trait_mod:<is>(Method $m, :sax-cb($)!) is export(:sax-cb) {
        $m does is-sax-cb;
    }

    sub atts2Hash(CArray[Str] $atts) is export(:atts2Hash) {
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
            sub ($obj, &callb) {
                sub (--> Str) {
                    callb($obj);
                }
            },
        'getLineNumber'|'getColumnNumber' =>
            sub ($obj, &callb) {
                sub (--> UInt) {
                    callb($obj);
                }
            },
    );

    my %SAXHandlerDispatch = %(
        'characters'|'ignorableWhitespace'|'cdataBlock' =>
            -> $obj, &callb {
            sub (parserCtxt $ctx, CArray[byte] $chars, int32 $len) {
                    # ensure null termination
                    sub memcpy(Blob $dest, CArray $chars, size_t $n) is native {*};
                    my buf8 $char-buf .= new;
                    $char-buf[$len-1] = 0
                        if $len > 0;
                    memcpy($char-buf, $chars, $len);
                    callb($obj, $char-buf.decode, :$ctx);
                }
        },
        'internalSubset'|'externalSubset' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, Str $external-id, Str $system-id) {
                    callb($obj, $name, :$ctx, :$external-id, :$system-id);
                }
        },
        'isStandalone'|'hasInternalSubset'|'hasExternalSubset' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx --> UInt) {
                    callb($obj, :$ctx);
                }
        },
        'resolveEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id --> xmlParserInput) {
                    callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'getEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name --> xmlEntity) {
                    callb($obj, $name, :$ctx);
                }
        },
        'entityDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id) {
                    callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'attributeDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) {
                    callb($obj, $elem, $fullname, :$ctx, :$type, :$def, :$default-value, :$tree);
                }
        },
        'elementDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) {
                    callb($obj, $name, :$ctx, :$type, :$content);
                }
        },
        'unparsedEntityDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    callb($obj, $name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'setDocumentLocator' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, xmlSAXLocator $locator) {
                    callb($obj, $locator, :$ctx);
                }
        },
        'startDocument'|'endDocument' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx) {
                    callb($obj, :$ctx);
                }
        },
        'startElement' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, CArray[Str] $atts) {
                    callb($obj, $name, :$ctx, :$atts);
                }
        },
        'endElement'|'reference'|'comment'|'warning'|'error'|'fatalError'|'getParameterEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $text) {
                    callb($obj, $text, :$ctx);
                }
        },
        'processingInstruction' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $target, Str $data) {
                    callb($obj, $target, $data, :$ctx);
                }
        },
        # Introduced with SAX2 
        'startElementNs' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) {
                    callb($obj, $local-name, :$ctx, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-attributes, :$num-defaulted, :$attributes);
                }
        },
        'endElementNs' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) {
                    callb($obj, $local-name, :$ctx, :$prefix, :$uri);
                }
        },
        'serror' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, xmlError $error) {
                    callb($obj, $error, :$ctx);
                }
        },

    );

    method !build(Any:D $obj, $handler, %dispatches) {
        my Bool %seen;
        for $obj.^methods.grep(* ~~ is-sax-cb) -> &meth {
            my $name = &meth.name;
            with %dispatches{$name} -> &dispatch {
                %seen{$name} = True;
                $handler."$name"() = &dispatch($obj, &meth);
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

    method build-sax-handler($obj, xmlSAXHandler :$sax = xmlSAXHandler.new) {
        $sax.init;
        self!build($obj, $sax, %SAXHandlerDispatch);
    }

    method build-sax-locator($obj, xmlSAXLocator :$locator = xmlSAXLocator.new) {
        self!build($obj, $locator, %SAXLocatorDispatch);
    }
}
