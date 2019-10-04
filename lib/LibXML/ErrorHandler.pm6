use v6;
use NativeCall;
use LibXML::Native;
use LibXML::Native::Defs :XML2;
use LibXML::Enums;

class X::LibXML is Exception {
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

    has UInt $.level = XML_ERR_ERROR;
    has UInt $.domain-num = XML_FROM_PARSER;
    method domain returns Str { @ErrorDomains[$!domain-num // 0] }
    has X::LibXML $.prev is rw;
}

class X::LibXML::AdHoc is X::LibXML {
    has Exception $.error handles<message>;
}

class X::LibXML::XPath::AdHoc is X::LibXML::AdHoc {
    method domain-num {XML_FROM_XPATH}
}

class X::LibXML::IO::AdHoc is X::LibXML::AdHoc {
    method domain-num {XML_FROM_IO}
}

class X::LibXML::Parser is X::LibXML {

    has Str $.file;
    has UInt $.line;
    has UInt $.column;
    has UInt $.code;
    has Str $.msg;

    method message {
        my @meta;
        @meta.push: $_ with $.domain;
        if $.level ~~ XML_ERR_ERROR|XML_ERR_FATAL  {
            @meta.push: 'error';
        }
        elsif $.level == XML_ERR_WARNING {
            @meta.push: 'warning';
        }

        my $prev = do with $.prev { .message ~ "\n" } // '';
        my $where = ($!line
                     ?? join(':', ($!file//''), $!line,  ' ')
                     !! '');
        my $message = chomp(@meta.join(' ') ~ ' : ' ~ $!msg);
        $prev ~ $where ~ $message;
    }
}

class LibXML::ErrorHandler {
    has X::LibXML @!errors;
    has Bool $.recover is rw;
    has Bool $.suppress-warnings;
    has Bool $.suppress-errors;
    has $.sax-handler;

    sub generic-error-cb(Str:D $fmt, |args) is export(:generic-error-cb) {
        CATCH { default { warn "error handling XML generic error: $_" } }
        $*XML-CONTEXT.generic-error($fmt, |args);
    }

    sub structured-error-cb($ctx, xmlError $err) is export(:structured-error-cb) {
        CATCH { default { warn "error handling XML structured error: $_" } }
        $*XML-CONTEXT.structured-error($err);
    }

    method !sax-error-cb-structured(xmlError:D $err) {
        with $!sax-handler -> $sax {
            $_($err.ctxt, $err) with $sax.serror-cb;
        }
    }

    method !sax-error-cb-unstructured(UInt:D $level, Str $msg) {
        # unstructured error handler
        with $!sax-handler -> $sax {
            my &cb = do given $level {
                when XML_ERR_FATAL   { $sax.fatalError-cb // $sax.error-cb }
                when XML_ERR_ERROR   { $sax.error-cb }
                when XML_ERR_WARNING { $sax.warning-cb }
            }
            $_(xmlParserCtxt, $msg.chomp) with &cb;
        }
    }

    method generic-error(Str $fmt, *@args) {
        CATCH { default { warn "error handling failure: $_" } }
        my $msg = sprintf($fmt, |@args);
        @!errors.push: X::LibXML::Parser.new( :level(XML_ERR_FATAL), :$msg );
        self!sax-error-cb-unstructured(XML_ERR_FATAL, $msg);
    }

    method structured-error(xmlError $_) {
        CATCH { default { warn "error handling failure: $_" } }
        my Int $level = .level;
        my Str $file = .file;
        my UInt:D $line = .line;
        my UInt:D $column = .column;
        my UInt:D $code = .code;
        my UInt:D $domain-num = .domain;
        my Str $msg = .message;
        $msg //= do with xmlParserErrors($code) { .key } else { $code.Str }

        @!errors.push:  X::LibXML::Parser.new( :$level, :$msg, :$file, :$line, :$column, :$code, :$domain-num );

        self!sax-error-cb-structured($_);
        self!sax-error-cb-unstructured($level, $msg);
    }

    method callback-error(X::LibXML $_) {
        @!errors.push: $_;
    }

    method is-valid(|c) {
        my Bool $valid = True;
        if @!errors {
            my X::LibXML @errs;
            for @!errors {
                if .domain-num ~~ XML_FROM_VALID|XML_FROM_SCHEMASV|XML_FROM_RELAXNGV|XML_FROM_SCHEMATRONV {
		    $valid = False;
		}
                else {
                    @errs.push: $_;
		}
	    }
            @!errors = @errs;
	}
	$valid;
    }

    method flush-errors(:$recover = $.recover) {
        if @!errors {
            my X::LibXML @errs = @!errors;
            @!errors = ();

            if $!suppress-errors {
                @errs .= grep({ .level > XML_ERR_ERROR })
            }
            elsif $!suppress-warnings {
                @errs .= grep({ .level >= XML_ERR_ERROR })
            }

            if @errs {
                my X::LibXML $fatal = @errs.first: { .level >= XML_ERR_ERROR };
                my X::LibXML $err = @errs.tail;
                @errs[$_].prev = @errs[$_-1] for 1 ..^ +@errs;

                if !$fatal.defined || $recover {
                    warn $err; 
                }
                else {
                    die $err;
                }
            }
        }
    }

    our sub cast-var-args(Str $fmt, CArray $argv) {
        constant %Type = %( :f(num64), :d(int32), :s(Str) );
        my int $n = 0;
        $fmt.comb.map({ nativecast( %Type{$_}, $argv[$n++] )});
    }

    sub set-generic-error-handler( &func (Str $fmt, Str $argt, CArray[Pointer] $argv), Pointer ) is native(XML2) is symbol('xmlSetGenericErrorFunc') {*}

    method SetGenericErrorFunc(&handler) {
        set-generic-error-handler(
            -> Str $msg, Str $fmt, CArray[Pointer] $argv {
                CATCH { default { warn $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
                my @args = cast-var-args($fmt, $argv);
                &handler($msg, @args);
            },
            xml6_gbl_message_func
        );
    }
}

=begin pod
=head1 NAME

LibXML::ErrorHandler - Structured Errors

=head1 SYNOPSIS



  try { ... }
  with $! {
      when X::LibXML::Parser {
        # handle a parse error
      }
      default {
        # error, but not a parser error
      } else {
  }

  print $!.message();
  my UInt $error-level = $!.level;
  my UInt $code = $!.code;
  my Str  $filename = $!.file;
  my UInt $line = $!.line();
  my UInt $offset = $!.column;
  my UInt $domain = $!.domain;

=head1 DESCRIPTION

The X:LibXML::Parser exception class is a tiny frontend to I<<<<<< libxml2 >>>>>>'s structured error support. If LibXML is compiled with structured error
support, all errors reported by libxml2 are transformed to X::LibXML::Parser
exception objects. These objects automatically serialize to the corresponding error
messages when printed or used in a string operation, but as objects, can also
be used to get a detailed and structured information about the error that
occurred. 

=begin item1
message

  Str $text = $!.message();

This function serializes an X:LibXML::Parser object to a string containing the
full error message close to the message produced by I<<<<<< libxml2 >>>>>> default error handlers and tools like xmllint. This method is also used to
overload "" operator on X:LibXML::Parser, so it is automatically called whenever
X:LibXML::Parser object is treated as a string (e.g. in print $@). 

=end item1

=begin item1
msg

  if $!.msg.chomp eq 'attributes construct error' { ... }

The raw message text. This may include a trailing new line.

=end item1

=begin item1
prev

  my X::LibXML::Parser$previous-error = $!.prev();

This field can possibly refer to another X::LibXML::Parser object
representing an error which occurred just before this error.

=end item1

=begin item1
messages

  say $!.messages();

A concatenation of the current $!.msg with any linked $!.prev errors. This
is used as the base text by the $!.message method.

=end item1


=begin item1
code

  my UInt $error-code = $!.code();
  if $!.code == XML_ERR_SPACE_REQUIRED { ... }

Returns the actual libxml2 error code. The LibXML::Enums module defines
constants for individual error codes. Currently libxml2 uses over 480 different
error codes. 

=end item1

=begin item1
message

  $error_message = @!.message();

Returns a human-readable informative error message.

=end item1

=begin item1
level

  $error_level = $!.level();

Returns an integer value describing how consequent is the error. LibXMNL::Enums
defines the following enumerations: 

=item2 * XML_ERR_NONE = 0

=item2 * XML_ERR_WARNING = 1 : A simple warning.

=item2 * XML_ERR_ERROR = 2 : A recoverable error.

=item2 * XML_ERR_FATAL = 3 : A fatal error.

=end item1

=begin item1
file

  my Str $filename = $!.file();

Returns the filename of the file being processed while the error occurred. 

=end item1

=begin item1
line

  my UInt $line-no = $!.line();

The line number, if available.

=end item1

=begin item1
column

  my UInt $offset = $!.column();

See C<<<<<< $@-&gt;column() >>>>>> above. 

=end item1

=begin item1
domain

  if $!.domain == XML_FROM_PARSER {...}

Returns the domain which raised the error as a number

=end item1

=begin item1
domain-name

  if $!.domain-name eq 'parser' {...}

Returns string containing information about what part of the library raised the
error. Can be one of: "parser", "tree", "namespace", "validity", "HTML parser",
"memory", "output", "I/O", "ftp", "http", "XInclude", "XPath", "xpointer",
"regexp", "Schemas datatype", "Schemas parser", "Schemas validity", "Relax-NG
parser", "Relax-NG validity", "Catalog", "C14N", "XSLT", "validity".

=end item1

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
