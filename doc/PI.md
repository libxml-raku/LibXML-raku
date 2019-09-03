NAME
====

LibXML::PI - LibXML Processing Instructions

SYNOPSIS
========

    use LibXML::Document;
    use LibXML::PI;
    # Only methods specific to Processing Instruction nodes are listed here,
    # see the LibXML::Node manpage for other methods

    my LibXML::Document $dom .= new;
    my LibXML::PI $pi = $dom.createProcessingInstruction("abc");

    $pi.setData( $data_string );
    $pi.setData( name=>string_value [...] );

DESCRIPTION
===========

Processing instructions are implemented with LibXML with read and write access. The PI data is the PI without the PI target (as specified in XML 1.0 [17]) as a string. This string can be accessed with getData as implemented in [LibXML::Node ](LibXML::Node ).

Many processing instructions have attribute like data. Therefore setData() provides, in addition to the DOM spec, the passing of named parameters. So the code segment:

    my LibXML::PI $pi = $dom.createProcessingInstruction("abc");
    $pi.setData(foo=>'bar', foobar=>'foobar');
    $dom.appendChild( $pi );

will result the following PI in the DOM:

    <?abc foo="bar" foobar="foobar"?>

Which is how it is specified in the DOM specification. This three step interface creates temporary a node in perl space. This can be avoided while using the insertProcessingInstruction() method. Instead of the three calls described above, the call

    $dom.insertProcessingInstruction("abc",'foo="bar" foobar="foobar"');

will have the same result as above.

[LibXML::PI ](LibXML::PI )'s implementation of setData() documented below differs a bit from the standard version as available in [LibXML::Node ](LibXML::Node ):

  * setData

        $pinode.setData( $data_string );
        $pinode.setData( name=>string_value [...] );

    This method allows one to change the content data of a PI. Additionally to the interface specified for DOM Level2, the method provides a named parameter interface to set the data. This parameter list is converted into a string before it is appended to the PI.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

