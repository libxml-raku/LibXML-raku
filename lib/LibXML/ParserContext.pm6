class LibXML::ParserContext {
    use NativeCall;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::ErrorHandler;

    has parserCtxt $!struct handles <wellFormed valid>;
    has uint32 $.flags;
    has Bool $.line-numbers;
    has $.input-callbacks;
    has $.sax-handler;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors> .= new;

    method recover { ?($!flags +& XML_PARSE_RECOVER) }
    method suppress-warnings { ?($!flags +& XML_PARSE_NOWARNING) }
    method suppress-errors { ?($!flags +& XML_PARSE_NOERROR) }

    method unbox { with self { $!struct } else { parserCtxt }  }
    method struct is rw {
        Proxy.new(
            FETCH => sub ($) { $!struct },
            STORE => sub ($, parserCtxt $struct) {
                with $!struct {
                    .Free if .remove-reference;
                }
                with $struct {
                    .add-reference;

                    .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
                    .linenumbers = +?$!line-numbers;
                    .SetStructuredErrorFunc: -> parserCtxt:D $ctx, xmlError:D $err {
                        self.structured-error($err);
                        $ctx.StopParser
                            if $err.level ~~ XML_ERR_FATAL;
                    };
                    $!struct = $_;
                    $!struct.sax = .unbox with $!sax-handler;
                }
            });
        }

    submethod TWEAK(parserCtxt :$struct) {
        self.struct = $_ with $struct;
    }

    submethod DESTROY {
        with $!struct {
            .Free if .remove-reference;
        }
    }

    method try(&action, Bool :$recover is copy) {

        my $obj = self;
        $_ = .new: :struct(parserCtxt.new)
            without $obj;

        $recover //= $obj.recover;

        my @contexts = .make-contexts
            with $obj.input-callbacks;

        for @contexts {
            xmlRegisterInputCallbacks(
                .match, .open, .read, .close
            );
        }

        &*chdir(~$*CWD);

        my $rv := action();

        if @contexts {
            xmlCleanupInputCallbacks();
            xmlRegisterDefaultInputCallbacks();
        }

        $obj.flush-errors: :$recover;

        $rv;
    }

}
