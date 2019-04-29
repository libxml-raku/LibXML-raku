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
    has parserCtxt:D $.ctx = xmlParserCtxt.new;
    has @!errors;
    has uint32 $.flags;
    has $.input-callbacks;

    method recover { ?($!flags +& XML_PARSE_RECOVER) }
    method suppress-warnings { ?($!flags +& XML_PARSE_NOWARNING) }
    method suppress-errors { ?($!flags +& XML_PARSE_NOERROR) }

    submethod TWEAK(Bool :$line-numbers) {
        $!ctx.add-reference;

        $!ctx.UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
        $!ctx.linenumbers = +$_ with $line-numbers;

        $!ctx;
    }

    submethod DESTROY {
        given $!ctx {
            .Free if .remove-reference;
        }
    }

    method !flush-errors(:$recover = $.recover) {
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

    method try(&action, Bool :$recover = $.recover) {

        sub structured-err-func(parserCtxt $ctx, xmlError $_) {
            constant @ErrorDomains = ("", "parser", "tree", "namespace", "validity",
                                      "HTML parser", "memory", "output", "I/O", "ftp",
                                      "http", "XInclude", "XPath", "xpointer", "regexp",
                                      "Schemas datatype", "Schemas parser", "Schemas validity",
                                      "Relax-NG parser", "Relax-NG validity",
                                      "Catalog", "C14N", "XSLT", "validity", "error-checking",
                                      "xmlwriter", "dynamic loading", "i18n",
                                      "Schematron validity");
            my Int $level = .level;
            my Str $msg = .message;
            my @text;
            @text.push: $_ with @ErrorDomains[.domain];
            if $level ~~ XML_ERR_ERROR|XML_ERR_FATAL  {
                @text.push: 'error';
                $ctx.StopParser
                    if $level ~~ XML_ERR_FATAL || !$recover;
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

        $!ctx.xmlSetGenericErrorFunc( sub (parserCtxt $, Str $msg) { @!errors.push: %( :level(XML_ERR_FATAL), :$msg ) });
        $!ctx.xmlSetStructuredErrorFunc( &structured-err-func );

        my @contexts = .make-contexts
           with $!input-callbacks;

        for @contexts {
            xmlRegisterInputCallbacks(
                .match, .open, .read, .close
            );
        }

        my $rv := action();

        xmlPopInputCallbacks()
            for @contexts;

        self!flush-errors: :$recover;

        $rv;
    }

}
