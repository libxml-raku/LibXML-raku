class LibXML::Parser::Context {
    use NativeCall;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::ErrorHandler;
    use LibXML::_Options;

    has xmlParserCtxt $!native handles <wellFormed valid>;
    has uint32 $.flags is rw = 0;
    has Bool $.line-numbers;
    has $.input-callbacks;
    has $.sax-handler;
    has LibXML::ErrorHandler $!errors handles<generic-error structured-error flush-errors is-valid> .= new: :$!sax-handler;

    our constant %Opts = %(
        :clean-namespaces(XML_PARSE_NSCLEAN),
        :complete-attributes(XML_PARSE_DTDATTR),
        :dtd(XML_PARSE_DTDLOAD +| XML_PARSE_DTDVALID
             +| XML_PARSE_DTDATTR +| XML_PARSE_NOENT),
        :expand-entities(XML_PARSE_NOENT),
        :expand-xinclude(XML_PARSE_XINCLUDE),
        :huge(XML_PARSE_HUGE),
        :load-ext-dtd(XML_PARSE_DTDLOAD),
        :no-base-fix(XML_PARSE_NOBASEFIX),
        :no-blanks(XML_PARSE_NOBLANKS),
        :no-keep-blanks(XML_PARSE_NOBLANKS),
        :no-cdata(XML_PARSE_NOCDATA),
        :no-def-dtd(HTML_PARSE_NODEFDTD),
        :no-network(XML_PARSE_NONET),
        :no-xinclude-nodes(XML_PARSE_NOXINCNODE),
        :old10(XML_PARSE_OLD10),
        :oldsax(XML_PARSE_OLDSAX),
        :pedantic-parser(XML_PARSE_PEDANTIC),
        :recover(XML_PARSE_RECOVER),
        :recover-quietly(XML_PARSE_RECOVER +| XML_PARSE_NOWARNING),
        :recover-silently(XML_PARSE_RECOVER +| XML_PARSE_NOERROR),
        :suppress-errors(XML_PARSE_NOERROR),
        :suppress-warnings(XML_PARSE_NOWARNING),
        :validation(XML_PARSE_DTDVALID),
        :xinclude(XML_PARSE_XINCLUDE),
    );

   also does LibXML::_Options[%Opts];

    method native { $!native }

    method set-native(xmlParserCtxt $native) {
        .Reference with $native;
        .Unreference with $!native;

        with $native {
            .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
            .linenumbers = +?$!line-numbers;
            .SetStructuredErrorFunc: -> xmlParserCtxt:D $ctx, xmlError:D $err {
                $*XML-CONTEXT.structured-error($err);
            };
            $!native = $_;
            $!native.sax = .native with $!sax-handler;
        }
    }

    submethod TWEAK(xmlParserCtxt :$native) {
        self.set-native($_) with $native;
    }

    submethod DESTROY {
        $*ERR.print('-');
        .Unreference with $!native;
    }

    method try(&action, Bool :$recover is copy, Bool :$check-valid) {

        my $*XML-CONTEXT = self;
        $_ = .new: :native(xmlParserCtxt.new)
            without $*XML-CONTEXT;

        $recover //= $*XML-CONTEXT.recover;

        my @input-contexts = .make-contexts
            with $*XML-CONTEXT.input-callbacks;

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

	$rv := $*XML-CONTEXT.is-valid if $check-valid;
        $*XML-CONTEXT.flush-errors: :$recover;

        $rv;
    }

    method FALLBACK($key, |c) is rw {
        $.option-exists($key)
            ?? $.option($key, |c)
            !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }
}
