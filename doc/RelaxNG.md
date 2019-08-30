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

    The DOM parameter allows one to parse the schema from a pre-parsed [LibXML::Document ](LibXML::Document ).

    Note that the constructor will die() if the schema does not meed the constraints of the RelaxNG specification.

  * validate

        try { $rngschema->validate( $doc ); };

    This function allows one to validate a (parsed) document against the given RelaxNG schema. The argument of this function should be an LibXML::Document object. If this function succeeds, it will return 0, otherwise it will die() and report the errors found. Because of this validate() should be always evaluated.

  * is-valid

        my Bool $valid = $rngschema.is-valid($doc);

    Returns either True or False depending on whether the passed Document is valid or not.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, Shlomi Fish, Tobias Leich, Xliff, David Warring

VERSION
=======

2.0200

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

