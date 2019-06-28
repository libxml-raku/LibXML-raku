use v6;
use NativeCall;
use LibXML::Native;
use LibXML::Enums;

class X::LibXML::Parser is Exception {

    has Str $.text;
    has Str $.file;
    has UInt $.line;
    has UInt $.column;
    has UInt $.level;
    
    method message {
        my $msg = join(':', $!file, $!line, ' ' ~ $!text);
        chomp $msg;
    }
}

class LibXML::ErrorHandler {
    constant @ErrorDomains = (
        "", "parser", "tree", "namespace", "validity",
        "HTML parser", "memory", "output", "I/O", "ftp",
        "http", "XInclude", "XPath", "xpointer", "regexp",
        "Schemas datatype", "Schemas parser", "Schemas validity",
        "Relax-NG parser", "Relax-NG validity",
        "Catalog", "C14N", "XSLT", "validity", "error-checking",
        "xmlwriter", "dynamic loading", "i18n",
        "Schematron validity",
    );

    has @!errors;
    method generic-error(Str $fmt, Pointer $arg) {
        my $msg = $fmt eq '%s' ?? nativecast(Str, $arg) !! $fmt;
        @!errors.push: %( :level(XML_ERR_FATAL), :$msg );
    }
    has Bool $.recover;
    has Bool $.suppress-warnings;
    has Bool $.suppress-errors;

    method generic-warning(Str $fmt, Pointer $arg) {
        my $msg = $fmt eq '%s' ?? nativecast(Str, $arg) !! $fmt;
        @!errors.push: %( :level(XML_ERR_WARNING), :$msg );
    }

    method structured-error(xmlError $_) {

        my Int $level = .level;
        my Str $msg = .message;
        my @text;
        @text.push: $_ with @ErrorDomains[.domain];
        if $level ~~ XML_ERR_ERROR|XML_ERR_FATAL  {
            @text.push: 'error';
        }
        elsif $level == XML_ERR_WARNING {
            @text.push: 'warning';
        }
        $msg = join(' : ', @text.join(' '), $msg)
            if @text;
        
        my $file = .file;
        my UInt:D $line = .line;
        my UInt:D $column = .column;
        @!errors.push: %( :$level, :$msg, :$file, :$line, :$column );

    }

    method flush-errors(:$recover = $.recover) {
        if @!errors {
            my @errs = @!errors;
            @!errors = ();
            if $!suppress-errors {
                @errs .= grep({ .<level> > XML_ERR_ERROR })
            }
            elsif $!suppress-warnings {
                @errs .= grep({ .<level> >= XML_ERR_ERROR })
            }

            if @errs {
                my Str $text = @errs.map(*<msg>).join;
                my $fatal = @errs.first: { .<level> >= XML_ERR_ERROR };

                my UInt:D $line   = @errs[0]<line>;
                my UInt:D $column = @errs[0]<column>;
                my UInt:D $level  = @errs[0]<level>;
                my Str $file = @errs[0]<file> // '';
                my X::LibXML::Parser $err .= new: :$text, :$file, :$line, :$column, :$level;
                if !$fatal || $recover {
                    warn $err; 
                }
                else {
                    die $err;
                }
            }
        }
    }

}
