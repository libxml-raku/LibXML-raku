#| Builds SAX callback sets
class LibXML::SAX::Builder {

    use LibXML::Raw;
    use LibXML::Raw::Defs :$CLIB;
    use LibXML::ErrorHandling;
    use LibXML::Node;
    use LibXML::Entity;

    use NativeCall;

    my role is-sax-cb[Str $name] is export(:is-sax-cb) {
        method sax-name { $name }
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

    sub handle-error(xmlParserCtxt $ctx, Exception $err) {
        CATCH { default { note "error handling SAX error: $_" } }
        with $ctx {
            .ParserError($err.message ~ "\n");
        }
        else {
            note "SAX errror: $err";
        }
    }

    my %SAXHandlerDispatch = %(
        'characters'|'ignorableWhitespace'|'cdataBlock' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    # ensure null termination
                    sub memcpy(Blob $dest, CArray $chars, size_t $n) is native($CLIB) {*};
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
                    CATCH { default { handle-error($ctx, $_); UInt; } }
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
                    my $ent = callb($obj, $name, :$ctx);
                    $ent ~~ LibXML::Entity ?? .raw !! $ent;
                }
        },
        'entityDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Int $type, Str $public-id, Str $system-id, Str $content) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, $content, :$ctx, :$public-id, :$system-id, :$type);
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
                    callb($obj, $name, $content, :$ctx, :$type);
                }
        },
        'unparsedEntityDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'notationDecl' =>
            -> $obj, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id) {
                    CATCH { default { handle-error($ctx, $_,) } }
                    callb($obj, $name, :$ctx, :$public-id, :$system-id);
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
                    CATCH { default { note "error handling SAX error: $_" } }
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
                sub (X::LibXML $error) {
                    callb($obj, $error);
                }
        },
    );

    method !build(Any:D $obj, %dispatches) {
        my Bool %seen;
        for $obj.^methods.grep(* ~~ is-sax-cb) -> &meth {
            my $name = &meth.sax-name;
            with %dispatches{$name} -> &dispatch {
                warn "duplicate SAX callback: $name"
                    if %seen{$name}++;
                $obj.set-sax-callback($name, &dispatch($obj, &meth));
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
        $obj;
    }

    method build-sax-handler($obj) {
        $obj.raw.init;
        self!build($obj, %SAXHandlerDispatch);
    }

}

=begin pod

=head2 Description

This class provides mappings from native SAX2 callbacks to Raku.

It may be used in conjunction with L<LibXML::SAX::Handler::SAX2> base-class.

=head2 Example

The following example builds a modified DOM tree with all tags
and attributes converted to uppercase.

    use LibXML::Document;
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

    my SAXShouter $sax-handler .= new();
    my $string = '<html><body><h1>Hello World</h1></body></html>'
    my LibXML::Document $doc .= parse: :$string, :$sax-handler;
    say $doc.Str;  # <HTML><BODY><H1>HELLO WORLD</H1></BODY></HTML>'

See L<LibXML::SAX::Handler::SAX2> for a description of callbacks

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
