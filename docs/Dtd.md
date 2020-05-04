class LibXML::Dtd
-----------------

LibXML DTD Handling

Synopsis
--------

```raku
use LibXML::Dtd;

my LibXML::Dtd $dtd .= new($public-id, $system-id);
my LibXML::Dtd $dtd .= parse: :string($dtd-str);
my Str $dtdName = $dtd.getName();
my Str $publicId = $dtd.publicId();
my Str $systemId = $dtd.systemId();
try { $dtd.validate($doc) };
my Bool $valid = $dtd.is-valid($doc);
if $doc ~~ $dtd { ... } # if doc is valid against the DTD
```

Description
-----------

This class holds a DTD. You may parse a DTD from either a string, or from an external SYSTEM identifier.

No support is available as yet for parsing from a filehandle.

LibXML::Dtd is a sub-class of [LibXML::Node ](https://libxml-raku.github.io/LibXML-raku/Node), so all the methods available to nodes (particularly Str()) are available to Dtd objects.

Methods
-------

### method new

```raku
# preferred constructor
multi method new(Str :$public-id, Str :$system-id) returns LibXML::Dtd
# for Perl compat
multi method new(Str $public-id, Str $system-id) returns LibXML::Dtd
```

Parse a DTD from the system identifier, and return a DTD object that you can pass to $doc.is-valid() or $doc.validate().

```raku
my $dtd = LibXML::Dtd.new(
                      "SOME // Public / ID / 1.0",
                      "test.dtd"
                                );
my $doc = LibXML.load: :file("test.xml");
$doc.validate($dtd);

$doc.is-valid($dtd);
#-OR-
$doc ~~ $dtd;
```

### method parse

```raku
method parse(Str :string) returns LibXML::Dtd;
```

The same as new() above, except you can parse a DTD from a string. Note that parsing from string may fail if the DTD contains external parametric-entity references with relative URLs.

### method validate

```perl6
method validate(
    LibXML::Node:D $node
) returns UInt
```

validate a parsed XML document against a DTD

This function allows one to validate a (parsed) document against the given XML Schema. The argument of this function should be a [LibXML::Document ](https://libxml-raku.github.io/LibXML-raku/Document) object. If this function succeeds, it will return 0, otherwise it will die() and report the errors found. Because of this validate() should be always evaluated.

### method is-valid

```perl6
method is-valid(
    LibXML::Node:D $node
) returns Bool
```

Returns True if the passed document is valid against the DTD

### method getName

```raku
method getName() returns Str
```

Returns the name of DTD; i.e., the name immediately following the DOCTYPE keyword.

### method publicId

```raku
method publicId() returns Str
```

Returns the public identifier of the external subset.

### method systemId

```raku
method systemId() returns Str
```

Returns the system identifier of the external subset.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

