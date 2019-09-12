class LibXML::SAX::Builder {
    use LibXML::Native;
    use LibXML::Native::Defs :CLIB;
    use NativeCall;

    use LibXML::Node;
    use LibXML::Entity;

    my role is-sax-cb[Str $name] is export(:is-sax-cb) {
        method sax-name { $name.subst(/<[-_]>(.)/, {$0.uc}, :g) }
    }
    multi trait_mod:<is>(Method $m, :sax-cb($cb)!) is export(:sax-cb) {
        my Str $name := $cb ~~ Str ?? $cb !! $m.name;
        $m does is-sax-cb[$name];
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

    sub handle-error(xmlParserCtxt $ctx, Exception $err, :$ret) {
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
                sub (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    # ensure null termination
                    sub memcpy(Blob $dest, CArray $chars, size_t $n) is native(CLIB) {*};
                    my buf8 $char-buf .= new;
                    $char-buf[$len-1] = 0
                        if $len > 0;
                    memcpy($char-buf, $chars, $len);
                    callb($obj, $char-buf.decode, :$ctx);
                }
        },
        'internalSubset'|'externalSubset' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$external-id, :$system-id);
                }
        },
        'isStandalone'|'hasInternalSubset'|'hasExternalSubset' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx --> UInt) {
                    CATCH { default { handle-error($ctx, $_, :ret(UInt)) } }
                    my UInt $ := callb($obj, :$ctx);
                }
        },
        'resolveEntity' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $public-id, Str $system-id --> xmlParserInput) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    my xmlParserInput $ := callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'getEntity' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name --> xmlEntity) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    my LibXML::Entity $ent := callb($obj, $name, :$ctx);
                    $ent.native;
                }
        },
        'entityDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $public-id, Str $system-id) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, :$ctx, :$public-id, :$system-id);
                }
        },
        'attributeDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $elem, $fullname, :$ctx, :$type, :$def, :$default-value, :$tree);
                }
        },
        'elementDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$type, :$content);
                }
        },
        'unparsedEntityDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'setDocumentLocator' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, xmlSAXLocator $locator) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $locator, :$ctx);
                }
        },
        'startDocument'|'endDocument' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, :$ctx);
                }
        },
        'startElement' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, CArray[Str] $atts-raw) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    my $attribs = atts2Hash($atts-raw);
                    callb($obj, $name, :$ctx, :$atts-raw, :$attribs);
                }
        },
        'endElement'|'reference'|'comment'|'getParameterEntity' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $text) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $text, :$ctx);
                }
        },
        'warning'|'error'|'fatalError' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $text) {
                    CATCH { default { warn "unable to handle error: $_" } }
                    callb($obj, $text, :$ctx);
                }
        },
        'processingInstruction' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $target, Str $data) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $target, $data, :$ctx);
                }
        },
        # Introduced with SAX2 
        'startElementNs' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-atts, int32 $num-defaulted, CArray[Str] $atts-raw) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $local-name, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-atts, :$num-defaulted, :$atts-raw, :$ctx );
                }
        },
        'endElementNs' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $local-name, :$prefix, :$uri, :$ctx);
                }
        },
        'serror' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, xmlError $error) {
                    callb($obj, $error, :$ctx);
                }
        },

    );

    method !build(Any:D $obj, $handler, %dispatches) {
        my Bool %seen;
        for $obj.^methods.grep(* ~~ is-sax-cb) -> &meth {
            my $name = &meth.sax-name;
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

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
