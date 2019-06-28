NAME
====

LibXML::RegExp - LibXML::RegExp - interface to libxml2 regular expressions

SYNOPSIS
========

    use LibXML::RegExp;
    my LibXML::RegExp $compiled-re .= new(rexexp => '[0-9]{5}(-[0-9]{4})?');
    if $compiled-re.isDeterministic() { ... }
    if $compiled-re.matches($string) { ... }

    my LibXML::RegExp $compiled-re .= new( :$regexp );
    my Bool $matched = $compiled-re.matches($string);
    my Bool $det     = $compiled-re.isDeterministic();

DESCRIPTION
===========

This is a perl interface to libxml2's implementation of regular expressions, which are used e.g. for validation of XML Schema simple types (pattern facet).

  * new()

        my LibXML::RegExp $compiled-re .= new( :$regexp );

    The constructor takes a string containing a regular expression and returns an object that contains a compiled regexp.

  * matches($string)

        my Bool $matched = $compiled-re.matches($string);

    Given a string value, returns True if the value is matched by the compiled regular expression.

  * isDeterministic()

        my Bool $det = $compiled-re.isDeterministic();

    Returns True if the regular expression is deterministic; returns False otherwise. (See the definition of determinism in the XML spec ([http://www.w3.org/TR/REC-xml/#determinism ](http://www.w3.org/TR/REC-xml/#determinism )))

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas

Ported from Perl 5 to 6 by David Warring <david.warring@gmail.com>

VERSION
=======

2.0132

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

