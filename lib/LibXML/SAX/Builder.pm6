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
        'characters'|'ignorableWhitespace'|'cdataBlock' =>
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
        'internalSubset'|'externalSubset' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name, Str $external-id, Str $system-id) {
                    method($obj, $name, :$ctx, :$external-id, :$system-id);
                }
        },
        'isStandalone'|'hasInternalSubset'|'hasExternalSubset' =>
            -> $obj, &method {
                sub (parserCtxt $ctx --> UInt) {
                    method($obj, :$ctx);
                }
        },
        'resolveEntity' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id --> xmlParserInput) {
                    method($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'getEntity' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name --> xmlEntity) {
                    method($obj, $name, :$ctx);
                }
        },
        'entityDecl' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id) {
                    method($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'attributeDecl' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) {
                    method($obj, $elem, $fullname, :$ctx, :$type, :$def, :$default-value, :$tree);
                }
        },
        'elementDecl' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) {
                    method($obj, $name, :$ctx, :$type, :$content);
                }
        },
        'unparsedEntityDecl' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    method($obj, $name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'setDocumentLocator' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, xmlSAXLocator $locator) {
                    method($obj, $locator, :$ctx);
                }
        },
        'startDocument'|'endDocument' =>
            -> $obj, &method {
                sub (parserCtxt $ctx) {
                    method($obj, :$ctx);
                }
        },
        'startElement' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $name, CArray[Str] $atts) {
                    method($obj, $name, :$ctx, :$atts);
                }
        },
        'endElement'|'reference'|'comment'|'warning'|'error'|'fatalError'|'getParameterEntity' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $text) {
                    method($obj, $text, :$ctx);
                }
        },
        'processingInstruction' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $target, Str $data) {
                    method($obj, $target, $data, :$ctx);
                }
        },
        # Introduced with SAX2 
        'startElementNs' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) {
                    method($obj, $local-name, :$ctx, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-attributes, :$num-defaulted, :$attributes);
                }
        },
        'endElementNs' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) {
                    method($obj, $local-name, :$ctx, :$prefix, :$uri);
                }
        },
        'serror' =>
            -> $obj, &method {
                sub (parserCtxt $ctx, xmlError $error) {
                    method($obj, $error, :$ctx);
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
