Description
-----------

The X::LibXML exception class hierarchy interfaces to *libxml2*'s structured error support. If LibXML is compiled with structured error support, all errors reported by libxml2 are transformed to X::LibXML exception objects. These objects automatically serialize to the corresponding error messages when printed or used in a string operation, but as objects, can also be used to get a detailed and structured information about the error that occurred.

Methods common to all X::LibXML exceptions
------------------------------------------

### method message

    $error_message = @!.message();

Returns a human-readable informative error message.

### method level

    $error_level = $!.level();

Returns an integer value describing how consequent is the error. [LibXMNL::Enums](LibXMNL::Enums) defines the following enumerations:

  * XML_ERR_NONE = 0

  * XML_ERR_WARNING = 1 : A simple warning.

  * XML_ERR_ERROR = 2 : A recoverable error.

  * XML_ERR_FATAL = 3 : A fatal error.

### method prev

    method prev() returns X::LibXML

This field can possibly refer to another X::LibXML::Parser object representing an error which occurred just before this error.

### method domain-num

    method domain-num() returns UInt
    if $err.domain-num == XML_FROM_PARSER {...}

Returns the domain which raised the error as a number

### method domain

    method domain returns Str
    if $err.domain eq 'parser' {...}

Returns a string containing information about what part of the library raised the error. Can be one of: "parser", "tree", "namespace", "validity", "HTML parser", "memory", "output", "I/O", "ftp", "http", "XInclude", "XPath", "xpointer", "regexp", "Schemas datatype", "Schemas parser", "Schemas validity", "Relax-NG parser", "Relax-NG validity", "Catalog", "C14N", "XSLT", "validity".

class X::LibXML::AdHoc
----------------------

LibXML ad-hoc errors

Exceptions raised in callbacks are wrapped in an X::LibXML::Adhoc (if not already of type X::LibXML), stashed into a `$*XML-CONTEXT` or `$*XPATH-CONTEXT` variable, and re-raised on return from the calling function.

### method error

    method error() returns Exception

The trapped error

class X::LibXML::XPath::AdHoc
-----------------------------

Ad-hoc exceptions from Raku XPath functions

class X::LibXML::IO::AdHoc
--------------------------

Ad-hoc exceptions from Raku Input callbacks

class X::LibXML::OpFail
-----------------------

LibXML Reader exceptions

class X::LibXML::Parser
-----------------------

LibXML Parser exceptions

### method message

    method message() returns Str

This function serializes an X::LibXML::Parser object to a string containing the full error message close to the message produced by *libxml2* default error handlers and tools like xmllint.

### method msg

    method msg() returns Str

The raw message text. This may include a trailing new line.

### method code

    my UInt $error-code = $!.code();
    method code() returns UInt
    if $err.code == XML_ERR_SPACE_REQUIRED { ... }

Returns the actual libxml2 error code. The [LibXML::Enums](https://libxml-raku.github.io/LibXML-raku/Enums) module defines constants for individual error codes. Currently libxml2 uses over 480 different error codes.

### method file

    method file() returns Str

Returns the filename of the file being processed while the error occurred.

### method line

    method line() returns UInt

The line number, if available.

### method column

    method column() returns UInt

The column, if available.



LibXML Exceptions and Error Handling

Synopsis
--------

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

Custom Error Handling
---------------------

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
            note $error.nessage;
        }
    }
    my SaxHandler $sax-handler .= new();
    # for example, parse a string with custom error handling
    my LibXML::Document $doc .= parse: :$string, :$sax-handler, :suppress-warnings;

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

