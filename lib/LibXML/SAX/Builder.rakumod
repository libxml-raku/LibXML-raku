#| Builds SAX callback sets
class LibXML::SAX::Builder {

    use LibXML::Raw;
    use LibXML::Raw::Defs :$CLIB, :$BIND-XML2;
    use LibXML::ErrorHandling;
    use LibXML::Node;
    use LibXML::Dtd::Entity;

    use NativeCall;

    #| for marshalling of startElementNs attributes
    class NsAtt is repr('CStruct') is export(:NsAtt) {
        sub xml6_sax_slice(Pointer, Pointer --> Str) is native($BIND-XML2) {*};
        has Str $.local-name;
        has Str $.prefix;
        has Str $.URI;
        has Pointer $!value-start;
        has Pointer $!value-end;
        method key {
            with $!prefix {
                $_ ~ ':' ~ $!local-name
            }
            else {
                $!local-name
            }
        }
        method value {
            xml6_sax_slice($!value-start, $!value-end);
        }
        
    }
    class NsAtts is repr('CPointer') {
        my constant att-size = nativesizeof(NsAtt);
        method Pointer { nativecast(Pointer, self) }
        sub memcpy(Pointer:D, Pointer:D, size_t) is native($CLIB) {*}
        method AT-POS(UInt:D $idx) {
            my Pointer:D $src .= new(+self.Pointer  +  $idx * att-size);
            given NsAtt.new -> $dest {
                memcpy(nativecast(Pointer, $dest), $src, att-size);
                $dest
            }
        }
        method atts2Hash(UInt:D $elems) {
            my % = (0 ..^ $elems).map: {
                my $att := self[$_];
                $att.key => $att;
            }
        }
    }

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

    sub callback-error(Exception $err) {
        CATCH { default { note "error handling SAX error $err: $_" } }
        $*XML-CONTEXT.callback-error: $err;
    }

    my %SAXHandlerDispatch = %(
        'characters'|'ignorableWhitespace'|'cdataBlock' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) {
                    CATCH { default { callback-error $_ } }
                    # ensure null termination
                    sub memcpy(Blob $dest, CArray $chars, size_t $n) is native($CLIB) {*};
                    my buf8 $char-buf .= allocate($len);
                    memcpy($char-buf, $chars, $len);
                    $saxh.&callb($char-buf.decode, :$ctx);
                }
        },
        'internalSubset'|'externalSubset' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($name, :$ctx, :$external-id, :$system-id);
                }
        },
        'isStandalone'|'hasInternalSubset'|'hasExternalSubset' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx --> UInt) {
                    CATCH { default { callback-error $_; UInt; } }
                    my UInt $ := $saxh.&callb(:$ctx);
                }
        },
        'resolveEntity' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $public-id, Str $system-id --> xmlParserInput) {
                    CATCH { default {callback-error $_ } }
                    my xmlParserInput $ := $saxh.&callb(:$ctx, :$public-id, :$system-id);
                }
        },
        'getEntity' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name --> xmlEntity) {
                    CATCH { default {callback-error $_ } }
                    my $ent := $saxh.&callb($name, :$ctx);
                    $ent ~~ LibXML::Dtd::Entity ?? .raw !! $ent;
                }
        },
        'entityDecl' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Int $type, Str $public-id, Str $system-id, Str $content) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($name, $content, :$ctx, :$public-id, :$system-id, :$type);
                }
        },
        'attributeDecl' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($elem, $fullname, :$ctx, :$type, :$def, :$default-value, :$tree);
                }
        },
        'elementDecl' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($name, $content, :$ctx, :$type);
                }
        },
        'unparsedEntityDecl' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($name, :$ctx, :$public-id, :$system-id, :$notation-name);
                }
        },
        'notationDecl' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($name, :$ctx, :$public-id, :$system-id);
                }
        },
        'setDocumentLocator' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, xmlSAXLocator $locator) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($locator, :$ctx);
                }
        },
        'startDocument'|'endDocument' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb(:$ctx);
                }
        },
        'startElement' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $name, CArray[Str] $atts-raw) {
                    CATCH { default {callback-error $_ } }
                    my $attribs = atts2Hash($atts-raw);
                    $saxh.&callb($name, :$ctx, :$atts-raw, :$attribs);
                }
        },
        'endElement'|'reference'|'comment'|'getParameterEntity' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $text) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($text, :$ctx);
                }
        },
        'warning'|'error'|'fatalError' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $text) {
                    CATCH { default { note "error handling SAX error: $_" } }
                    $saxh.&callb($text, :$ctx);
                }
        },
        'processingInstruction' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $target, Str $data) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($target, $data, :$ctx);
                }
        },
        # Introduced with SAX2
        'startElementNs' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-atts, int32 $num-defaulted, CArray[Str] $atts-raw) {
                    CATCH { default { callback-error $_ } }
                    my $attribs := nativecast(NsAtts, $atts-raw);
                    my UInt $n = $num-atts - $num-defaulted;
                    my NsAtt %attribs = .atts2Hash($n)
                        with $attribs;
 
                    $saxh.&callb($local-name, :$prefix, :$uri, :$num-namespaces, :$namespaces, :$num-atts, :$num-defaulted, :%attribs, :$atts-raw, :$ctx );
                }
        },
        'endElementNs' =>
            -> $saxh, &callb {
                sub (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) {
                    CATCH { default {callback-error $_ } }
                    $saxh.&callb($local-name, :$prefix, :$uri, :$ctx);
                }
        },
        'serror' =>
            -> $saxh, &callb {
                sub (X::LibXML $error) {
                    $saxh.&callb($error);
                }
        },
    );

    method !build(Any:D $saxh, %dispatches) {
        my Bool %seen;
        for $saxh.^methods.grep(* ~~ is-sax-cb) -> &meth {
            my $name = &meth.sax-name;
            with %dispatches{$name} -> &dispatch {
                warn "duplicate SAX callback: $name"
                    if %seen{$name}++;
                $saxh.set-sax-callback($name, &dispatch($saxh, &meth));
            }
            else {
                my $known = %dispatches.keys.sort.join: ' ';
                die "unknown SAX method $name. expected: $known";
            }
        }
        for <Element ElementNS> {
            warn "'start$_', 'end$_' callbacks not paired"
                if %seen{'start'~ $_}.so !=== %seen{'end'~ $_}.so
        }
        warn "'startElement' and 'startElementNs' callbacks are mutually exclusive"
            if %seen<startElement> && %seen<startElementNs>;
        $saxh;
    }

    method build-sax-handler($saxh) {
        $saxh.raw.init;
        self!build($saxh, %SAXHandlerDispatch);
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
