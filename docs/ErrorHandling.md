NAME
====

LibXML::ErrorHandling - libxml exceptions and error handling

SYNOPSIS
========

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

DESCRIPTION
===========

The X:LibXML::Parser exception class interfaces to *libxml2 *'s structured error support. If LibXML is compiled with structured error support, all errors reported by libxml2 are transformed to X::LibXML::Parser exception objects. These objects automatically serialize to the corresponding error messages when printed or used in a string operation, but as objects, can also be used to get a detailed and structured information about the error that occurred.

X:LibXML::Parser Methods
========================

  * message

        Str $text = $!.message();

    This function serializes an X:LibXML::Parser object to a string containing the full error message close to the message produced by *libxml2 * default error handlers and tools like xmllint. This method is also used to overload "" operator on X:LibXML::Parser, so it is automatically called whenever X:LibXML::Parser object is treated as a string (e.g. in print $@). 

  * msg

        if $!.msg.chomp eq 'attributes construct error' { ... }

    The raw message text. This may include a trailing new line.

  * prev

        my X::LibXML::Parser$previous-error = $!.prev();

    This field can possibly refer to another X::LibXML::Parser object representing an error which occurred just before this error.

  * messages

        say $!.messages();

    A concatenation of the current $!.msg with any linked $!.prev errors. This is used as the base text by the $!.message method.

  * code

        my UInt $error-code = $!.code();
        if $!.code == XML_ERR_SPACE_REQUIRED { ... }

    Returns the actual libxml2 error code. The [LibXML::Enums](https://libxml-raku.github.io/LibXML-raku/Enums) module defines constants for individual error codes. Currently libxml2 uses over 480 different error codes. 

  * message

        $error_message = @!.message();

    Returns a human-readable informative error message.

  * level

        $error_level = $!.level();

    Returns an integer value describing how consequent is the error. [LibXMNL::Enums](LibXMNL::Enums) defines the following enumerations:

      * XML_ERR_NONE = 0

      * XML_ERR_WARNING = 1 : A simple warning.

      * XML_ERR_ERROR = 2 : A recoverable error.

      * XML_ERR_FATAL = 3 : A fatal error.

  * file

        my Str $filename = $!.file();

    Returns the filename of the file being processed while the error occurred. 

  * line

        my UInt $line-no = $!.line();

    The line number, if available.

  * column

        my UInt $offset = $!.column();

    See `$@-&gt;column() ` above. 

  * domain

        if $!.domain == XML_FROM_PARSER {...}

    Returns the domain which raised the error as a number

  * domain-name

        if $!.domain-name eq 'parser' {...}

    Returns string containing information about what part of the library raised the error. Can be one of: "parser", "tree", "namespace", "validity", "HTML parser", "memory", "output", "I/O", "ftp", "http", "XInclude", "XPath", "xpointer", "regexp", "Schemas datatype", "Schemas parser", "Schemas validity", "Relax-NG parser", "Relax-NG validity", "Catalog", "C14N", "XSLT", "validity".

Custom Error Handling
=====================

Parsers that perform the LibXML::ErrorHandling role can install their own error-handling callbacks via SAX Handler. `warning()`, `error()` or `errorFatal()` callbacks can be defined for simple error handling or a `serror()` callback can be defined to handle everything as `X::LibXML` exception objects.

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

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

