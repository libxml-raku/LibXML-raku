class LibXML::RegExp
--------------------

interface to libxml2 regular expressions

Synopsis
--------

    use LibXML::RegExp;
    my LibXML::RegExp $compiled-re .= compile('[0-9]{5}(-[0-9]{4})?');
    my LibXML::RegExp $compiled-re .= new(rexexp => '[0-9]{5}(-[0-9]{4})?');
    if $compiled-re.isDeterministic() { ... }
    if $compiled-re.matches($string) { ... }
    if $string ~~ $compiled-re { ... }

    my LibXML::RegExp $compiled-re .= new( :$regexp );
    my Bool $matched = $compiled-re.matches($string);
    my Bool $det     = $compiled-re.isDeterministic();

Description
-----------

This is a Raku interface to libxml2's implementation of regular expressions, which are used e.g. for validation of XML Schema simple types (pattern facet).

Methods
-------

method new
----------

    method new(Str :$regexp) returns LibXML
    my LibXML::RegExp $compiled-re .= new( :$regexp );

The new constructor takes a string containing a regular expression and return an object that contains a compiled regexp.

### method compile

```perl6
method compile(
    Str:D $regexp
) returns LibXML::RegExp
```

Compile constructor

`LibXML::RegExp.compile($regexp)` is equivalent to `LibXML::RegExp.new(:$regexp)`

### multi method ACCEPTS

```perl6
multi method ACCEPTS(
    Str:D $content
) returns Bool
```

(alias matches) Returns True if $content matches the regular expression

### method isDeterministic

```perl6
method isDeterministic() returns Bool
```

Returns True if the regular expression is deterministic.

(See the definition of determinism in the XML spec [http://www.w3.org/TR/REC-xml/#determinism ](http://www.w3.org/TR/REC-xml/#determinism ))

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

