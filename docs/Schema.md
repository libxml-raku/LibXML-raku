[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Schema](https://libxml-raku.github.io/LibXML-raku/Schema)

class LibXML::Schema
--------------------

XML Schema Validation

Synopsis
--------

    use LibXML::Schema;
    use LibXML;

    my $doc = LibXML.new.parse: :file($url);

    my LibXML::Schema $xmlschema  .= new( location => $filename_or_url );
    my LibXML::Schema $xmlschema2 .= new( string => $xmlschemastring );
    try { $xmlschema.validate( $doc ); };
    if $doc ~~ $xmlschema { ... }

Description
-----------

The LibXML::Schema class is a tiny frontend to libxml2's XML Schema implementation. Currently it supports only schema parsing and document validation. libxml2 only supports decimal types up to 24 digits (the standard requires at least 18).

Methods
-------

### method new

    multi method new( Str :$location!, *%opts ) returns LibXML::Schema
    multi method new( Str :string!,  *%opts ) returns LibXML::Schema
    multi method new( LibXML::Document :$doc!,  *%opts ) returns LibXML::Schema

The constructor of LibXML::Schema may get called with either one of two parameters. The parameter tells the class from which source it should generate a validation schema. It is important, that each schema only have a single source.

The location parameter allows one to parse a schema from the filesystem or a URL.

The `:network` flag effects processing of `xsd:import` directives. By default this is disabled, unless a custom External Entity Loader has been installed via the [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config)`.external-entity-loader` method. More detailed control can then be achieved by setting up a custom entity loader, or by using input callbacks configured via the [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config) `.input-callbacks` method.

The string parameter will parse the schema from the given XML string.

Note that the constructor will die() if the schema does not meet the constraints of the XML Schema specification.

### method validate

    multi method validate(LibXML::Document $doc) returns Int
    multi method validate(LibXML::Element $elem) returns Int
    try { $xmlschema.validate( $doc ); };

This function allows one to validate a document, or a root element against the given XML Schema. If this function succeeds, it will return 0, otherwise it will die() and report the errors found.

### method is-valid

    multi method is-valid(LibXML::Document $doc) returns Bool
    multi method is-valid(LibXML::Element $elem) returns Bool

### multi method ACCEPTS

```raku
multi method ACCEPTS(
    LibXML::Node:D $node
) returns Bool
```

Returns either True or False depending on whether the Document or Element is valid or not.

Example:

```raku
$valid = $doc ~~ $xmlschema;
```

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

