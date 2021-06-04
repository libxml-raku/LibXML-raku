[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)

class LibXML::Dtd
-----------------

LibXML DTD Handling

Synopsis
--------

```raku
use LibXML::Dtd;
use LibXML::Entity;
use LibXML::Dtd::Notation;
use LibXML::Dtd::ElementDecl;
use LibXML::Dtd::AttrDecl;

my LibXML::Dtd $dtd .= new($public-id, $system-id);
my LibXML::Dtd $dtd .= parse: :string($dtd-str);

# Information retrieval
my Str $dtdName = $dtd.getName();
my Str $publicId = $dtd.publicId();
my Str $systemId = $dtd.systemId();
my Bool $is-html = $dtd.is-XHTML;

my LibXML::Entity = $dtd.getEntity("bar");
my LibXML::Dtd::Notation $foo = $dtd.getNotation("foo");
my LibXML::Dtd::ElementDecl $elem-decl = $dtd.getElementDeclaration($elem-name);
my LibXML::Dtd::AttrDecl $attr-decl = $dtd.getAttrDeclaration($elem-name, $attr-name);
# get declaration associated with an element, attribute or entity reference
my LibXML::Node $node-decl = $dtd.getNodeDeclaration($node);

# Associative Interfaces
my LibXML::Dtd::DeclMap $entities = $dtd.entities;
$foo = $entities<foo>;
my LibXML::Dtd::DeclMap $notations = $dtd.notations;
$bar = $notations<bar>;
my LibXML::Dtd::DeclMap $elem-decls = $dtd.element-declarations;
$elem-decl = $elem-decls{$elem-name}
my LibXML::Dtd::AttrDeclMap $elem-attr-decls = $dtd.element-attribute-declarations;
$attr-decl = $elem-attr-decls{$elem-name}{$attr-name};

# Validation
try { $dtd.validate($doc) };
my Bool $valid = $dtd.is-valid($doc);
if $doc ~~ $dtd { ... } # if doc is valid against the DTD
```

Description
-----------

This class holds a DTD. You may parse a DTD from either a string, or from an external SYSTEM identifier.

No support is available as yet for parsing from a filehandle.

LibXML::Dtd is a sub-class of [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node), so all the methods available to nodes (particularly Str()) are available to Dtd objects.

Methods
-------

### method new

    # preferred constructor
    multi method new(Str :$public-id, Str :$system-id) returns LibXML::Dtd
    # for Perl compat
    multi method new(Str $public-id, Str $system-id) returns LibXML::Dtd

Parse a DTD from the system identifier, and return a DTD object that you can pass to $doc.is-valid() or $doc.validate().

    my $dtd = LibXML::Dtd.new(
                          "SOME // Public / ID / 1.0",
                          "test.dtd"
                                    );
    my $doc = LibXML.load: :file("test.xml");
    $doc.validate($dtd);

    $doc.is-valid($dtd);
    #-OR-
    $doc ~~ $dtd;

### method parse

    method parse(Str :string) returns LibXML::Dtd;

The same as new() above, except you can parse a DTD from a string. Note that parsing from string may fail if the DTD contains external parametric-entity references with relative URLs.

### method getNotation

```raku
method getNotation(
    Str $name
) returns LibXML::Dtd::Notation
```

Notation declaration lookup

### method getEntity

```raku
method getEntity(
    Str $name
) returns LibXML::Entity
```

Entity declaration lookup

### method getElementDeclaration

```raku
method getElementDeclaration(
    Str $name
) returns LibXML::Dtd::ElementDecl
```

Element declaration lookup

### method getAttrDeclaration

```raku
method getAttrDeclaration(
    Str $elem-name,
    Str $attr-name
) returns LibXML::Dtd::AttrDecl
```

Attribute declaration lookup

### getNodeDeclaration

```raku
multi method getNodeDeclaration(LibXML::Element --> LibXML::Dtd::ElementDecl);
multi method getNodeDeclaration(LibXML::Attr --> LibXML::Dtd::AttrDecl);
multi method getNodeDeclaration(LibXML::EntityRef --> LibXML::Entity);
```

Looks up a definition in the DtD for a DOM Element, Attribute or Entity-Reference node

### method validate

    method validate($doc = $.ownerDocument --> UInt)

This function allows one to validate a (parsed) document against the given XML Schema. The argument of this function should be a [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) object. If this function succeeds, it will return 0, otherwise it will die() and report the errors found. Because of this validate() should be always evaluated.

### method is-valid

```raku
method is-valid(
    W3C::DOM::Document:D $doc
) returns Bool
```

Returns True if the passed document is valid against the DTD

### method is-XHTML

```raku
method is-XHTML() returns Bool
```

Returns True if the publicId or systemId match an XHTML identifier

Returns False if the Id's don't match or Bool:U if the DtD lack either a publicId or systemId

### method getName

    method getName() returns Str

Returns the name of DTD; i.e., the name immediately following the DOCTYPE keyword.

### method publicId

    method publicId() returns Str

Returns the public identifier of the external subset.

### method systemId

    method systemId() returns Str

Returns the system identifier of the external subset.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

