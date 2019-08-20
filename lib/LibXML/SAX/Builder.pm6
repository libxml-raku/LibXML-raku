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
            loop (my int $i = 0; my $key := .[$i++]; ) {
                %atts{$key} = .[$i++];
            }
        }
        %atts
    }

    my %SAXLocatorDispatch = %(
        'getPublicId'|'getSystemId' =>
            -> $obj, &callb {
                CATCH { default { warn $_; } }
                sub (--> Str) {
                    callb($obj);
                }
            },
        'getLineNumber'|'getColumnNumber' =>
            -> $obj, &callb {
                CATCH { default { warn $_; } }
                sub (--> UInt) {
                    callb($obj);
                }
            },
    );

    sub handle-error(parserCtxt $ctx, Exception $err, :$ret) {
        with $ctx {
            .ParserError($err.message ~ "\n");
        }
        else {
            warn $err;
        }
        $ret;
    }

    my %SAXHandlerDispatch = %(
        'characters'|'ignorableWhitespace'|'cdataBlock' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, CArray[byte] $chars, int32 $len) {
                    CATCH { default { handle-error($ctx, $_,) } }
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
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$external-id, :$system-id);
                }
        },
        'isStandalone'|'hasInternalSubset'|'hasExternalSubset' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx --> UInt) {
                    CATCH { default { handle-error($ctx, $_, :ret(UInt)) } }
                    callb($obj, :$ctx);
                }
        },
        'resolveEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id --> xmlParserInput) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'getEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name --> xmlEntity) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx);
                }
        },
        'entityDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $public-id, Str $system-id) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'attributeDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $elem, $fullname, :$ctx, :$type, :$def, :$default-value, :$tree);
                }
        },
        'elementDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$type, :$content);
                }
        },
        'unparsedEntityDecl' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'setDocumentLocator' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, xmlSAXLocator $locator) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $locator, :$ctx);
                }
        },
        'startDocument'|'endDocument' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, :$ctx);
                }
        },
        'startElement' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $name, CArray[Str] $atts) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$atts);
                }
        },
        'endElement'|'reference'|'comment'|'getParameterEntity' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $text) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $text, :$ctx);
                }
        },
        'warning'|'error'|'fatalError' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $text) {
                    CATCH { default { warn "unable to handle error: $_" } }
                    callb($obj, $text, :$ctx);
                }
        },
        'processingInstruction' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $target, Str $data) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $target, $data, :$ctx);
                }
        },
        # Introduced with SAX2 
        'startElementNs' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-atts, int32 $num-defaulted, CArray[Str] $atts) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $local-name, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-atts, :$num-defaulted, :$atts, :$ctx );
                }
        },
        'endElementNs' =>
            -> $obj, &callb {
                sub (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $local-name, :$prefix, :$uri, :$ctx);
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

=begin pod

=head1 NAME

LibXML::SAX::Builder - Building DOM trees from SAX events.

=head1 DESCRIPTION

This module provides mappings from native SAX callbacks to Perl. It is
usually used in conjunction with a LibXML::SAX::Handler base-class.

=head1 EXAMPLE

The following example builds a modified DOM tree with all tags
and attributes converted to uppercase.

    use LibXML::SAX::Builder;
    use LibXML::SAX::Handler::SAX2;

    class SAXShouter is LibXML::SAX::Handler::SAX2 {
        use LibXML::SAX::Builder :sax-cb;
        method startElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method endElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method characters($chars, |c) is sax-cb {
            nextwith($chars.uc, |c);
        }
    }


=end pod
