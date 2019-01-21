class LibXML::SAX::Builder {
    use LibXML::Native;
    use NativeCall;
    has xmlSAXHandler $.sax .= new;

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
                -> parserCtxt $ctx, Str $name, CArray[Str] $atts {
                    my %atts := atts-Hash($atts);
                    method($obj, $name, :$ctx, :%atts);
                }
            },
        endElement => 
            -> $obj, &method {
                -> parserCtxt $ctx, Str $name {
                    method($obj, $name, :$ctx);
                }
            },
    );

    submethod TWEAK {
        for %Dispatch.pairs.sort {
            my $name := .key;
            with self.can($name) -> $methods {
                my &dispatch := .value;
                $!sax."$name"() = dispatch(self, $methods[0])
                    if +$methods;
            }
        }
    }

}
