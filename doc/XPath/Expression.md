NAME
====

LibXML::XPath::Expression - LibXML::XPath::Expression - interface to libxml2 pre-compiled XPath expressions

SYNOPSIS
========

    use LibXML::XPath::Expression;
    my LibXML::XPath::Expression $compiled-xpath .= parse('//foo[@bar="baz"][position()<4]');

    # interface from LibXML::Node

    my $result = $node.find($compiled-xpath);
    my @nodes = $node.findnodes($compiled-xpath);
    my $value = $node.findvalue($compiled-xpath);

    # interface from LibXML::XPathContext

    my $result = $xpc.find($compiled-xpath,$node);
    my @nodes = $xpc.findnodes($compiled-xpath,$node);
    my $value = $xpc.findvalue($compiled-xpath,$node);

    $compiled = LibXML::XPath::Expression.new( xpath-string );

DESCRIPTION
===========

This is a perl interface to libxml2's pre-compiled XPath expressions. Pre-compiling an XPath expression can give in some performance benefit if the same XPath query is evaluated many times. `LibXML::XPath::Expression ` objects can be passed to all `find... ` functions `LibXML ` that expect an XPath expression. 

  * new()

        LibXML::XPath::Expression $compiled  = .new( :expr($xpath-string) );

    The constructor takes an XPath 1.0 expression as a string and returns an object representing the pre-compiled expressions (the actual data structure is internal to libxml2). 

  * parse()

        LibXML::XPath::Expression $compiled  = .parse( $xpath-string );

    Alternative constructor.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, 

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

