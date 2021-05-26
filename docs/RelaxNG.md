[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [RelaxNG](https://libxml-raku.github.io/LibXML-raku/RelaxNG)

class LibXML::RelaxNG
---------------------

RelaxNG Schema Validation

Synopsis
--------

```raku
use LibXML::RelaxNG;
use LibXML;

my $doc = LibXML.new.parse: :file($url);

my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
my LibXML::RelaxNG $rngschema .= new( :$doc );
try { $rngschema.validate( $doc ); };
if  $rngschema.is-valid( $doc ) {...}
if $doc ~~ $rngschema { ... }
```

Description
-----------

The LibXML::RelaxNG class is a tiny frontend to libxml2's RelaxNG implementation. Currently it supports only schema parsing and document validation.

Methods
-------

### method new

    multi method new( :location($filename_or_url) ) returns LibXML::RelaxNG;
    multi method new( :string($xml-schema-string) ) returns LibXML::RelaxNG;
    multi method new( LibXML::Document :$doc ) returns LibXML::RelaxNG;

The constructors for LibXML::RelaxNG may get called with either one of three parameters. The parameter tells the class from which source it should generate a validation schema. It is important, that each schema only have a single source.

The `:location` parameter allows one to parse a schema from the filesystem or a URL.

The `:string` parameter will parse the schema from the given XML string.

The `:doc` parameter allows one to parse the schema from a pre-parsed [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document).

Note that the constructor will die() if the schema does not meed the constraints of the RelaxNG specification.

### method validate

    try { $rngschema->validate( $doc ); };

This function allows one to validate a (parsed) document against the given RelaxNG schema. The argument of this function should be an LibXML::Document object. If this function succeeds, it will return 0, otherwise it will throw, reporting the found. Because of this validate() should be always be execute in a `try` block or in the scope of a `CATCH` block.

### method is-valid

    method is-valid(LibXML::Document $doc) returns Bool;
    $valid = $doc ~~ $rngschema;

Returns either True or False depending on whether the passed Document is valid or not.

### multi method ACCEPTS

```raku
multi method ACCEPTS(
    LibXML::Document:D $doc
) returns Bool
```

Returns True if the document validates against the given schema

Example:

```raku
$valid = $doc ~~ $rngschema;
```

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

