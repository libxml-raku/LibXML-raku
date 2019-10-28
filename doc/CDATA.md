NAME
====

LibXML::CDATA - LibXML Class for CDATA Sections

SYNOPSIS
========

    use LibXML::CDATA;
    # Only methods specific to CDATA nodes are listed here,
    # see the LibXML::Node documentation for other methods

    my LibXML::CDATA $cdata .= new( :$content );

    $cdata.data ~~ s/xxx/yyy/; # Stringy Interface - see LibXML::Text

DESCRIPTION
===========

This class provides all functions of [LibXML::Text ](LibXML::Text ), but for CDATA nodes.

METHODS
=======

The class inherits from [LibXML::Node ](LibXML::Node ). The documentation for Inherited methods is not listed here.

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/ ](http://www.w3.org/TR/DOM-Level-3-Core/ )). Please refer to the specification for extensive documentation.

  * new

        my LibXML::CDATA $node .= new( :$content );

    The constructor is the only provided function for this package. It is required, because *libxml2 * treats the different text node types slightly differently.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

