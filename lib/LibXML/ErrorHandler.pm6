class X::LibXML::Parser is Exception {
    use LibXML::Native;
    use LibXML::Enums;

    has Str $.text;
    has Str $.file;
    
    method message {
        my $msg = "Error while parsing {$!file // 'XML document'}";
        $msg ~= ":\n" ~ $_ with $!text;
        chomp $msg;
    }
}

class LibXML::ErrorHandler {
    use LibXML::Native;
    use LibXML::Enums;
    has parserCtxt $!ctx;
    has @!errors;
    has uint32 $.flags;
    has Bool $.line-numbers;
    has $.input-callbacks;
    has $.sax-handler;

    method recover { ?($!flags +& XML_PARSE_RECOVER) }
    method suppress-warnings { ?($!flags +& XML_PARSE_NOWARNING) }
    method suppress-errors { ?($!flags +& XML_PARSE_NOERROR) }

    method ctx is rw {
        Proxy.new(
            FETCH => sub ($) { $!ctx },
            STORE => sub ($, parserCtxt $ctx) {
                with $!ctx {
                    .Free if .remove-reference;
                }
                with $ctx {
                    .add-reference;

                    .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
                    .linenumbers = +?$!line-numbers;
                    .xmlSetGenericErrorFunc( self!generic-error-func );
                    .xmlSetStructuredErrorFunc( self!structured-error-func );
                    $!ctx = $_;
                    $!ctx.sax = .unbox with $!sax-handler;
                }
            });
        }

    submethod TWEAK(parserCtxt :$ctx) {
        self.ctx = $_ with $ctx;
    }

    submethod DESTROY {
        with $!ctx {
            .Free if .remove-reference;
        }
    }

    method !generic-error-func {
        -> parserCtxt $, Str:D $msg {
            @!errors.push: %( :level(XML_ERR_FATAL), :$msg );
        }
    }

    method !structured-error-func {

        constant @ErrorDomains = (
            "", "parser", "tree", "namespace", "validity",
            "HTML parser", "memory", "output", "I/O", "ftp",
            "http", "XInclude", "XPath", "xpointer", "regexp",
            "Schemas datatype", "Schemas parser", "Schemas validity",
            "Relax-NG parser", "Relax-NG validity",
            "Catalog", "C14N", "XSLT", "validity", "error-checking",
            "xmlwriter", "dynamic loading", "i18n",
            "Schematron validity"
        );

        -> $ctx, xmlError $_ {
            my Int $level = .level;
            my Str $msg = .message;
            my @text;
            @text.push: $_ with @ErrorDomains[.domain];
            if $level ~~ XML_ERR_ERROR|XML_ERR_FATAL  {
                @text.push: 'error';
                $ctx.StopParser
                    if $level ~~ XML_ERR_FATAL;
            }
            elsif $level == XML_ERR_WARNING {
                @text.push: 'warning';
            }
            $msg = (@text.join(' '), ' : ', $msg).join
                if @text;

            my $file = .file // '';
            if .line && !$file.ends-with('/') {
                $msg = ($file, .line, ' ' ~ $msg).join: ':';
            }
            @!errors.push: %( :$level, :$msg);
        }

    }

    method flush-errors(:$recover = $.recover) {
        if @!errors {
            my @errs = @!errors;
            @!errors = ();

            if $.suppress-errors {
                @errs .= grep({ .<level> > XML_ERR_ERROR })
            }
            elsif $.suppress-warnings {
                @errs .= grep({ .<level> >= XML_ERR_ERROR })
            }

            if @errs {
                my Str $text = @errs.map(*<msg>).join;
                my $fatal = @errs.first: { .<level> >= XML_ERR_ERROR };


                my X::LibXML::Parser $err .= new: :$text;
                if !$fatal || $recover {
                    warn $err; 
                }
                else {
                    die $err;
                }
            }
        }
    }

    method try(&action, Bool :$recover is copy) {

        my $obj = self;
        $_ = .new: :ctx(parserCtxt.new)
            without $obj;

        $recover //= $obj.recover;

        my @contexts = .make-contexts
           with $obj.input-callbacks;

        for @contexts {
            xmlRegisterInputCallbacks(
                .match, .open, .read, .close
            );
        }

        my $rv := action();

        xmlPopInputCallbacks()
            for @contexts;

        $obj.flush-errors: :$recover;

        $rv;
    }

}
