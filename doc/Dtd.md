NAME
====

LibXML::Dtd - LibXML DTD Handling

SYNOPSIS
========

    use LibXML;

    $dtd = LibXML::Dtd.new($public-id, $system-id);
    $dtd = LibXML::Dtd.parse: :string($dtd-str);
    my Str $dtdName = $dtd.getName();
    my Str $publicId = $dtd.publicId();
    my Str $systemId = $dtd.systemId();

DESCRIPTION
===========

This class holds a DTD. You may parse a DTD from either a string, or from an external SYSTEM identifier.

No support is available as yet for parsing from a filehandle.

LibXML::Dtd is a sub-class of [LibXML::Node ](LibXML::Node ), so all the methods available to nodes (particularly Str()) are available to Dtd objects.

METHODS
=======

  * new

        my LibXML::Dtd $dtd  .= new: :$public-id, :$system-id;
        my LibXML::Dtd $dtd2 .= new($public-id, $system-id);

    Parse a DTD from the system identifier, and return a DTD object that you can pass to $doc.is-valid() or $doc.validate().

        my $dtd = LibXML::Dtd.new(
                              "SOME // Public / ID / 1.0",
                              "test.dtd"
                                        );
         my $doc = LibXML.new.parse: :file("test.xml");
         $doc.validate($dtd);

  * parse

        my LibXML::Dtd $dtd .= parse: :string($dtd-str);

    The same as new() above, except you can parse a DTD from a string. Note that parsing from string may fail if the DTD contains external parametric-entity references with relative URLs.

  * getName

        my Str $name = $dtd.getName();

    Returns the name of DTD; i.e., the name immediately following the DOCTYPE keyword.

  * publicId

        my Str $publicId = $dtd.publicId();

    Returns the public identifier of the external subset.

  * systemId

        my Str $systemId = $dtd.systemId();

    Returns the system identifier of the external subset.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas

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

