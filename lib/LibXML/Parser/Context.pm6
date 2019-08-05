class LibXML::Parser::Context {
    use NativeCall;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::ErrorHandler;

    has parserCtxt $!native handles <wellFormed valid>;
    has uint32 $.flags;
    has Bool $.line-numbers;
    has $.input-callbacks;
    has $.sax-handler;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors is-valid> .= new;

    method recover { ?($!flags +& XML_PARSE_RECOVER) }
    method suppress-warnings { ?($!flags +& XML_PARSE_NOWARNING) }
    method suppress-errors { ?($!flags +& XML_PARSE_NOERROR) }

    method native is rw {
        Proxy.new(
            FETCH => sub ($) { $!native },
            STORE => sub ($, parserCtxt $native) {
                with $!native {
                    .Free if .remove-reference;
                }
                with $native {
                    .Reference;

                    .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
                    .linenumbers = +?$!line-numbers;
                    .SetStructuredErrorFunc: -> parserCtxt:D $ctx, xmlError:D $err {
                        self.structured-error($err);
                        $ctx.StopParser
                            if $err.level ~~ XML_ERR_FATAL;
                    };
                    $!native = $_;
                    $!native.sax = .native with $!sax-handler;
                }
            });
        }

    submethod TWEAK(parserCtxt :$native) {
        self.native = $_ with $native;
    }

    submethod DESTROY {
        with $!native {
            .Free if .remove-reference;
        }
    }

    method try(&action, Bool :$recover is copy, Bool :$check-valid) {

        my $obj = self;
        $_ = .new: :native(parserCtxt.new)
            without $obj;

        $recover //= $obj.recover;

        my @input-contexts = .make-contexts
            with $obj.input-callbacks;

        # just to make sure we've initialised
        xmlRegisterDefaultInputCallbacks();

        for @input-contexts {
            die "unable to register input callbacks"
            if xmlRegisterInputCallbacks(.match, .open, .read, .close) < 0;
        }

        &*chdir(~$*CWD);

        my $rv := action();

        for @input-contexts {
            warn "unable to remove input callbacks"
                if xmlPopInputCallbacks() < 0;
        }

	$rv := $obj.is-valid if $check-valid;
        $obj.flush-errors: :$recover;

        $rv;
    }

}
