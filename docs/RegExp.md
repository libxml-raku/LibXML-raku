NAME
====

LibXML::RegExp - LibXML::RegExp - interface to libxml2 regular expressions

SYNOPSIS
========

```raku
use LibXML::RegExp;
my LibXML::RegExp $compiled-re .= compile('[0-9]{5}(-[0-9]{4})?');
my LibXML::RegExp $compiled-re .= new(rexexp => '[0-9]{5}(-[0-9]{4})?');
if $compiled-re.isDeterministic() { ... }
if $compiled-re.matches($string) { ... }
if $string ~~ $compiled-re { ... }

my LibXML::RegExp $compiled-re .= new( :$regexp );
my Bool $matched = $compiled-re.matches($string);
my Bool $det     = $compiled-re.isDeterministic();
```

DESCRIPTION
===========

This is a Raku interface to libxml2's implementation of regular expressions, which are used e.g. for validation of XML Schema simple types (pattern facet).

  * new / compile

    ```raku
    my LibXML::RegExp $compiled-re .= compile( $regexp );
    my LibXML::RegExp $compiled-re .= new( :$regexp );
    ```

    The constructors takes a string containing a regular expression and return an object that contains a compiled regexp.

  * matches / ACCEPTS

    ```raku
    my Bool $matched = $compiled-re.matches($string);
    $matched = $string ~~ $compiled-re;
    ```

    Given a string value, returns True if the value is matched by the compiled regular expression.

  * isDeterministic()

    ```raku
    my Bool $det = $compiled-re.isDeterministic();
    ```

    Returns True if the regular expression is deterministic; returns False otherwise. (See the definition of determinism in the XML spec ([http://www.w3.org/TR/REC-xml/#determinism ](http://www.w3.org/TR/REC-xml/#determinism )))

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

