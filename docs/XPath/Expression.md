class LibXML::XPath::Expression
-------------------------------

Interface to LibXML pre-compiled XPath Expressions

Synopsis
--------

    use LibXML::XPath::Expression;
    my LibXML::XPath::Expression $compiled-xpath .= compile('//foo[@bar="baz"][position()<4]');

    # interface from LibXML::Node

    my $result = $node.find($compiled-xpath);
    my @nodes = $node.findnodes($compiled-xpath);
    my $value = $node.findvalue($compiled-xpath);

    # interface from LibXML::XPath::Context

    my $result = $xpc.find($compiled-xpath, $node);
    my @nodes = $xpc.findnodes($compiled-xpath, $node);
    my $value = $xpc.findvalue($compiled-xpath, $node);

    my LibXML::XPath::Expression $compiled .= new: :expr($xpath-string), :$node;

Description
-----------

This is a Raku interface to libxml2's pre-compiled XPath expressions. Pre-compiling an XPath expression can give in some performance benefit if the same XPath query is evaluated many times. `LibXML::XPath::Expression` objects can be passed to all `find...` functions in [LibXML](https://libxml-raku.github.io/LibXML-raku) that expect an XPath expression. 

Methods
-------

### method new

    method new(
        Str :expr($xpath)!, LibXML::Node :node($ref-node)
    ) returns LibXML::XPath::Expression

The constructor takes an XPath 1.0 expression as a string and returns an object representing the pre-compiled expressions (the actual data structure is internal to libxml2). 

### method compile

    method compile(
        Str $xpath,
        LibXML::Node :node($ref-node)
    ) returns LibXML::XPath::Expression;

Alternative constructor which takes a positional XPath expression as a string.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

