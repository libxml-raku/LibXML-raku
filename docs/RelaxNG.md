NAME
====

LibXML::RelaxNG - RelaxNG Schema Validation

SYNOPSIS
========

    use LibXML::Schema;
    use LibXML;

    my $doc = LibXML.new.parse: :file($url);

    my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
    my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
    my LibXML::RelaxNG $rngschema .= new( :$doc );
    try { $rngschema.validate( $doc ); };
    if  $rngschema.is-valid( $doc ) {...}
    if $doc ~~ $rngschema { ... }

DESCRIPTION
===========

The LibXML::RelaxNG class is a tiny frontend to libxml2's RelaxNG implementation. Currently it supports only schema parsing and document validation.

METHODS
=======

  * new

        my LibXML::RelaxNG $rngschema .= new( location => $filename_or_url );
        my LibXML::RelaxNG $rngschema .= new( string => $xmlschemastring );
        my LibXML::RelaxNG $rngschema .= new( :$doc );

    The constructor of LibXML::RelaxNG may get called with either one of three parameters. The parameter tells the class from which source it should generate a validation schema. It is important, that each schema only have a single source.

    The location parameter allows one to parse a schema from the filesystem or a URL.

    The string parameter will parse the schema from the given XML string.

    The DOM parameter allows one to parse the schema from a pre-parsed [LibXML::Document ](https://libxml-raku.github.io/LibXML-raku/Document ).

    Note that the constructor will die() if the schema does not meed the constraints of the RelaxNG specification.

  * validate

        try { $rngschema->validate( $doc ); };

    This function allows one to validate a (parsed) document against the given RelaxNG schema. The argument of this function should be an LibXML::Document object. If this function succeeds, it will return True, otherwise it will throw, reporting the found. Because of this validate() should be always be execute in a `try` block or in the scope of a `CATCH` block.

  * is-valid / ACCEPTCS

        my Bool $valid = $rngschema.is-valid($doc);
        $valid = $doc ~~ $rngschema;

    Returns either True or False depending on whether the passed Document is valid or not.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

