use v6;
use NativeCall;
use LibXML::Raw;
use LibXML::Raw::Defs :$BIND-XML2;
use LibXML::Enums;

class X::LibXML is Exception {
=begin pod
    =head2 Description

    =para The X::LibXML exception class hierarchy interfaces to I<libxml2>'s structured error support. If LibXML is compiled with structured error
    support, all errors reported by libxml2 are transformed to X::LibXML
    exception objects. These objects automatically serialize to the corresponding error
    messages when printed or used in a string operation, but as objects, can also
    be used to get a detailed and structured information about the error that
    occurred.

=end pod

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

=begin pod
    =head2 Methods common to all X::LibXML exceptions

    =head3 method message

      $error_message = @!.message();

    Returns a human-readable informative error message.

    =head3 method level

      $error_level = $!.level();

    Returns an integer value describing how consequent is the error. L<LibXMNL::Enums>
    defines the following enumerations:

      =item XML_ERR_NONE = 0

      =item XML_ERR_WARNING = 1 : A simple warning.

      =item XML_ERR_ERROR = 2 : A recoverable error.

      =item XML_ERR_FATAL = 3 : A fatal error.

    =head3 method prev

      method prev() returns X::LibXML

    This field can possibly refer to another X::LibXML::Parser object
    representing an error which occurred just before this error.

    =head3 method domain-num

      method domain-num() returns UInt
      if $err.domain-num == XML_FROM_PARSER {...}

    Returns the domain which raised the error as a number

    =head3 method domain

      method domain returns Str
      if $err.domain eq 'parser' {...}

    Returns a string containing information about what part of the library raised the
    error. Can be one of: "parser", "tree", "namespace", "validity", "HTML parser",
    "memory", "output", "I/O", "ftp", "http", "XInclude", "XPath", "xpointer",
    "regexp", "Schemas datatype", "Schemas parser", "Schemas validity", "Relax-NG
    parser", "Relax-NG validity", "Catalog", "C14N", "XSLT", "validity".

=end pod


}

#| LibXML ad-hoc errors
class X::LibXML::AdHoc is X::LibXML {
    has Exception $.error handles<message>;
}
=begin pod
    =para
    Exceptions raised in callbacks are wrapped in an X::LibXML::Adhoc (if not already of type X::LibXML), stashed into a
    `$*XML-CONTEXT` or `$*XPATH-CONTEXT` variable, and re-raised
    on return from the calling function.

    =head3 method error

        method error() returns Exception

    =para The trapped error
=end pod

#| Ad-hoc exceptions from Raku XPath functions
class X::LibXML::XPath::AdHoc is X::LibXML::AdHoc {
    method domain-num {XML_FROM_XPATH}
}

#|  Ad-hoc exceptions from Raku Input callbacks
class X::LibXML::IO::AdHoc is X::LibXML::AdHoc {
    method domain-num {XML_FROM_IO}
}

#| LibXML Reader exceptions
class X::LibXML::OpFail is X::LibXML {
    has Str:D $.what = 'Read';
    has Str:D $.op is required;
    method message { "XML $!what $!op operation failed" }
}

class X::LibXML::TooManyErrors is X::LibXML {
    has UInt:D $.max-errors is required;
    method msg { "Limit of $.max-errors warnings + errors reached" }
    method message {
        my $prev := do with $.prev { .message ~ "\n" } // '';
        $prev ~ $.msg;
    }
}

#| LibXML Parser exceptions
class X::LibXML::Parser is X::LibXML {

    has Str  $.file;
    has UInt $.line;
    has UInt $.column;
    has UInt $.code;
    has Str  $.msg;
    has Str  $.context;

    method message returns Str {
        my @meta;
        @meta.push: $_ with $.domain;
        if $.level >= XML_ERR_ERROR {
            @meta.push: 'error';
        }
        elsif $.level == XML_ERR_WARNING {
            @meta.push: 'warning';
        }

        my $prev := do with $.prev { .message ~ "\n" } // '';
        my $where = ($!line
                     ?? join(':', ($!file//''), $!line,  ' ')
                     !! '');
        my $body = chomp(@meta.join(' ') ~ ' : ' ~ $!msg);
        my $message = $prev ~ $where ~ $body;

        with $!context {
            $message ~= "\n" ~ $_;
            if $!column {
                my $pad = .substr(0, $!column-1).subst(/<[\S]>/, ' ', :g);
                $message ~= "\n" ~ $pad ~ '^'
            }
        }

        $message;
    }
=begin pod
    =head3 method message

      method message() returns Str

    This function serializes an X::LibXML::Parser object to a string containing the
    full error message close to the message produced by I<libxml2> default error handlers and tools like xmllint.

    =head3 method msg

      method msg() returns Str

    The raw message text. This may include a trailing new line.

    =head3 method code

      my UInt $error-code = $!.code();
      method code() returns UInt
      if $err.code == XML_ERR_SPACE_REQUIRED { ... }

    Returns the actual libxml2 error code. The L<LibXML::Enums> module defines
    constants for individual error codes. Currently libxml2 uses over 480 different
    error codes.

    =head3 method file

      method file() returns Str

    Returns the filename of the file being processed while the error occurred.

    =head3 method line

      method line() returns UInt

    The line number, if available.

    =head3 method column

      method column() returns UInt

    The column, if available.

=end pod

}

#| LibXML Exceptions and Error Handling
role LibXML::ErrorHandling {

    use LibXML::Config;
    has X::LibXML @!errors;
    has UInt $.max-errors = LibXML::Config.max-errors;

    # SAX External Callback
    sub generic-error-cb(Str:D $fmt, |args) is export(:generic-error-cb) {
        CATCH { default { note "error handling XML generic error: $_" } }
        $*XML-CONTEXT.generic-error($fmt, |args);
    }

    # SAX External Callback
    sub structured-error-cb($ctx, xmlError:D $err) is export(:structured-error-cb) {
        CATCH { default { note "error handling XML structured error: $_" } }
        $*XML-CONTEXT.structured-error($err);
    }

    # API Callback - structured
    method !sax-error-cb-structured(X::LibXML $err) {
        with self.sax-handler -> $sax {
            .($err) with $sax.serror-cb;
        }
    }

    # API Callback - unstructured
    method !sax-error-cb-unstructured(UInt:D $level, Str $msg) {
        # unstructured error handler
        with self.sax-handler -> $sax {
            my &cb = do given $level {
                when XML_ERR_FATAL   { $sax.fatalError-cb // $sax.error-cb }
                when XML_ERR_ERROR   { $sax.error-cb }
                when XML_ERR_WARNING { $sax.warning-cb }
            }
            .(xmlParserCtxt, $msg.chomp) with &cb;
        }
    }

    method generic-error(Str $fmt, *@args) {
        CATCH { default { note "error handling generic error: $_" } }
        my $msg = sprintf($fmt, |@args);

        if @!errors < $!max-errors {
            @!errors.push: X::LibXML::Parser.new( :level(XML_ERR_FATAL), :$msg );
            self!sax-error-cb-unstructured(XML_ERR_FATAL, $msg);
        }
        elsif @!errors == $!max-errors {
            @!errors.push: X::LibXML::TooManyErrors.new( :level(XML_ERR_FATAL), :$.max-errors );
            self!sax-error-cb-unstructured(XML_ERR_FATAL, @!errors.tail.msg);
        }
    }

    method structured-error(xmlError:D $_) {
        CATCH { default { note "error handling structured error: $_" } }

        if @!errors <= $!max-errors {
            my Int $level = .level;
            my Str $file = .file;
            my UInt:D $line = .line;
            my Str $context = .context(my uint32 $column);
            my UInt:D $code = .code;
            my UInt:D $domain-num = .domain;
            my Str $msg = .message;
            $column ||= .column;
            $msg //= do with xmlParserErrors($code) { .key } else { $code.Str }
            self.callback-error: X::LibXML::Parser.new( :$level, :$msg, :$file, :$line, :$column, :$code, :$domain-num, :$context );
        }
    }

    method callback-error(X::LibXML $err is copy) {
        unless @!errors > $!max-errors {
            $err = X::LibXML::TooManyErrors.new( :level(XML_ERR_FATAL), :$.max-errors )
                if @!errors == $!max-errors;

            @!errors.push: $err;
            self!sax-error-cb-structured($err);
            self!sax-error-cb-unstructured($err.level, $err.message);
        }
    }

    my subset ValidityError of X::LibXML where .domain-num ~~ XML_FROM_VALID|XML_FROM_SCHEMASV|XML_FROM_RELAXNGV|XML_FROM_SCHEMATRONV;

    method validity-check(|c) {
        my Bool $valid = True;
        if @!errors {
            my X::LibXML @errs;
            for @!errors {
                when ValidityError {
                    $valid = False;
                }
                default {
                    @errs.push: $_;
                }
            }
            @!errors = @errs;
        }
        $valid;
    }

    multi sub throw($,   X::LibXML:U) { }
    multi sub throw('e', X::LibXML:D $err) is hidden-from-backtrace { die $err }
    multi sub throw('w', X::LibXML:D $err) is hidden-from-backtrace { warn $err }

    method will-die(--> Bool) {
        @!errors.first(*.level >= XML_ERR_ERROR).defined;
    }

    method flush-errors(:$recover = $.recover) is hidden-from-backtrace {
        my X::LibXML @errs = @!errors;
        @!errors = ();

        if self.suppress-errors {
            @errs .= grep: *.level > XML_ERR_ERROR;
        }
        elsif self.suppress-warnings {
            @errs .= grep({ .level >= XML_ERR_ERROR })
        }

        my X::LibXML $fatal = @errs.first: *.level >= XML_ERR_ERROR;
        my X::LibXML $err = @errs.tail;
        @errs[$_].prev = @errs[$_-1] for 1 ..^ +@errs;
        my $lvl := $fatal.defined && ! $recover ?? 'e' !! 'w';
        throw($lvl, $err);
    }

    my class MsgArg is repr('CUnion') is export(:MsgArg) {
        has num64  $.f;
        has uint32 $.d;
        has long   $.l;
        has Str    $.s;
    }

    my sub unmarshal-varargs(Str $fmt, Pointer[MsgArg] $argv) is export(:unmarshal-varargs) {
        my int $n = 0;
        $fmt.comb.map: { $argv[$n++]."$_"() };
    }

    sub set-generic-error-handler( &func (Str $fmt, Str $argt, Pointer[MsgArg] $argv)) is native($BIND-XML2) is symbol('xml6_gbl_set_generic_error_handler') {*}

    method SetGenericErrorFunc(&handler) {
        set-generic-error-handler(
            -> Str $msg, Str $fmt, Pointer[MsgArg] $argv {
                CATCH { default { note $_; $*XML-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :error($_) } }
                my @args = unmarshal-varargs($fmt, $argv);
                &handler($msg, @args);
            }
        );
    }
}

=begin pod

=head2 Synopsis

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


=head2 Custom Error Handling

Parsers that perform the LibXML::ErrorHandling role can install their own error-handling callbacks via SAX Handlers. `warning()`, `error()` or `errorFatal()` callbacks can be defined for simple error handling or a `serror()` callback can be defined to handle everything as `X::LibXML` exception objects.

The `:suppress-warnings` and `:suppress-errors` flags are also needed if you wish to disable this module's built-in error handling.

    # Set up a custom SAX error handler
    use LibXML::SAX::Handler;
    class SaxHandler is LibXML::SAX::Handler {
        use LibXML::SAX::Builder :sax-cb;
        # handle just warnings
        method warning(Str $message) is sax-cb {
            warn $message;
        }
        # -OR-
        # handle all exceptions
        method serror(X::LibXML $error) is sax-cb {
            warn $error.message;
        }
    }
    my SaxHandler $sax-handler .= new();
    # for example, parse a string with custom error handling
    my LibXML::Document $doc .= parse: :$string, :$sax-handler, :suppress-warnings;

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
