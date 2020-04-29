NAME
====

LibXML::XPathContext - XPath Evaluation

SYNOPSIS
========

    use LibXML::XPathContext;
    use LibXML::Node;
    my LibXML::XPath::Context $xpc .= new();
    $xpc .= new(:$node, :suppress-warnings, :suppress-errors);
    $xpc.registerNs($prefix, $namespace-uri);
    $xpc.unregisterNs($prefix);
    my Str $uri = $xpc.lookupNs($prefix);
    $xpc.registerVarLookupFunc(&get-variable);
    my &func = $xpc.getVarLookupFunc();
    $xpc.unregisterVarLookupFunc;
    $xpc.registerFunctionNS($name, $uri, &callback);
    $xpc.unregisterFunctionNS($name, $uri);
    $xpc.registerFunction($name, &callback);
    $xpc.unregisterFunction($name);
    my @nodes = $xpc.findnodes($xpath);
    @nodes = $xpc.findnodes($xpath, $ref-node );
    $node = $xpc.first($xpath);
    $node = $xpc.last($xpath);
    my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $ref-node );
    my Any $object = $xpc.find($xpath );
    $object = $xpc.find($xpath, $ref-node );
    my $value = $xpc.findvalue($xpath );
    my Bool $found = $xpc.exists( $xpath, $ref-node );
    $xpc.contextNode = $node;
    $node = $xpc.contextNode;
    my Int $position = $xpc.contextPosition;
    $xpc.contextPosition = $position;
    my Int $size = $xpc.contextSize;
    $xpc.contextSize = $size;

DESCRIPTION
===========

The LibXML::XPath::Context class provides an almost complete interface to libxml2's XPath implementation. With LibXML::XPath::Context, it is possible to evaluate XPath expressions in the context of arbitrary node, context size, and context position, with a user-defined namespace-prefix mapping, custom XPath functions written in Raku, and even a custom XPath variable resolver. 

EXAMPLES
========

Namespaces
----------

This example demonstrates `registerNs() ` method. It finds all paragraph nodes in an XHTML document.

    my LibXML::XPath::Context $xc .= new: doc($xhtml-doc);
    $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');

Custom XPath functions
----------------------

This example demonstrates `registerFunction() ` method by defining a function filtering nodes based on a Raku regular expression:

    sub grep-nodes(LibXML::Node::Set $nodes, Str $regex) {
        $nodes.grep: {.textContent ~~ / <$regex> /};
    };
    # -OR-
    sub grep-nodes(Array() $nodes, Str $regex) {
        $nodes.grep: {.textContent ~~ / <$regex> /};
    };

    my LibXML::Document $doc .= parse: "example/article.xml";
    $node = $doc.root;
    my $xc = LibXML::XPath::Context.new(:$node);
    $xc.registerFunction('grep-nodes', &grep-nodes);
    @nodes = $xc.findnodes('grep-nodes(section,"^Bar")').list;

Variables
---------

This example demonstrates `registerVarLookup() ` method. We use XPath variables to recycle results of previous evaluations:

    sub var-lookup(Str $name, Str $uri, Hash $data) {
      return $data{$name};
    }

    my $areas = LibXML.new.parse: :file('areas.xml');
    my $empl = LibXML.new.parse: :file('employees.xml');

    my $xc = LibXML::XPath::Context.new(node => $empl);

    my %variables = (
      A => $xc.find('/employees/employee[@salary>10000]'),
      B => $areas.find('/areas/area[district='Brooklyn']/street'),
    );

    # get names of employees from $A working in an area listed in $B
    $xc.registerVarLookupFunc(&var-lookup, %variables);
    my @nodes = $xc.findnodes('$A[work_area/street = $B]/name');

METHODS
=======

  * new

        my LibXML::XPath::Context $xpc .= new();

    Creates a new LibXML::XPath::Context object without a context node.

        my LibXML::XPath::Context $xpc .= new: :$node;

    Creates a new LibXML::XPath::Context object with the context node set to `$node `.

  * registerNs

        $xpc.registerNs($prefix, $namespace-uri);

    Registers namespace `$prefix ` to `$namespace-uri `.

  * unregisterNs

        $xpc.unregisterNs($prefix);

    Unregisters namespace `$prefix `.

  * lookupNs

        $uri = $xpc.lookupNs($prefix);

    Returns namespace URI registered with `$prefix `. If `$prefix ` is not registered to any namespace URI returns `undef `.

  * registerVarLookupFunc

        $xpc.registerVarLookupFunc(&callback, |args);

    Registers variable lookup function `$prefix `. The registered function is executed by the XPath engine each time an XPath variable is evaluated. The callback function has two required arguments: `$data `, variable name, and variable ns-URI.

    The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g. Document, Element, etc.), [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) or [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List). For convenience, types: List, Seq and Slip can also be returned array references containing only [LibXML::Node ](https://libxml-raku.github.io/LibXML-raku/Node) objects can be used instead of an [LibXML::Node::Set ](https://libxml-raku.github.io/LibXML-raku/Node/Set).

    Any additional arguments are captured and passed to the callback function. For example:

        $xpc.registerVarLookupFunc(&my-callback, 'Xxx', :%vars);

    matches the signature:

    sub my-callback(Str $name, Str $uri, 'Xxx', :%vars!) { ... }

  * registerFunctionNS

        $xpc.registerFunctionNS($name, $uri, &callback, |args);

    Registers an extension function `$name ` in `$uri ` namespace. The arguments of the callback function are either simple scalars or `LibXML::* ` objects depending on the XPath argument types.

    The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g. Document, Element, etc.), [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) or [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List). For convenience, types: List, Seq and Slip can also be returned array references containing only [LibXML::Node ](https://libxml-raku.github.io/LibXML-raku/Node) objects can be used instead of an [LibXML::Node::Set ](https://libxml-raku.github.io/LibXML-raku/Node/Set).

  * unregisterFunctionNS

        $xpc.unregisterFunctionNS($name, $uri);

    Unregisters extension function `$name ` in `$uri ` namespace. Has the same effect as passing `undef ` as `$callback ` to registerFunctionNS.

  * registerFunction

        $xpc.registerFunction($name, &callback, |args);

    Same as `registerFunctionNS ` but without a namespace.

  * unregisterFunction

        $xpc.unregisterFunction($name);

    Same as `unregisterFunctionNS ` but without a namespace.

  * findnodes

        my LibXML::Node @nodes = $xpc.findnodes($xpath);

        @nodes = $xpc.findnodes($xpath, $context-node );

        my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $context-node );

    Performs the xpath statement on the current node and returns the result as an array. In item context, returns an [LibXML::Node::Set ](https://libxml-raku.github.io/LibXML-raku/Node/Set) object. Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

  * first, last

        my LibXML::Node $body = $doc.first('body');
        my LibXML::Node $last-row = $body.last('descendant::tr');

    The `first` and `last` methods are similar to `findnodes`, except they return a single node representing the first or last matching row. If no nodes were found, `LibXML::Node:U` is returned.

  * find

        my Any $object = $xpc.find($xpath );

        $object = $xpc.find($xpath, $context-node );

    Performs the xpath expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath `1 * 3 + 52 ` results in a Numeric object being returned. Other expressions might return a Bool object, or a [LibXML::Literal ](https://libxml-raku.github.io/LibXML-raku/Literal) object (a string). Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

  * findvalue

        my Str $value = $xpc.findvalue($xpath );

        my Str $value = $xpc.findvalue($xpath, $context-node );

    Is equivalent to:

        $xpc.find( $xpath, $context-node ).to-literal;

    That is, it returns the literal value of the results. This enables you to ensure that you get a string back from your search, allowing certain shortcuts. This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>. Optionally, a node may be passed in the second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression ](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

  * exists

        my Bool $found = $xpc.exists( $xpath-expression, $context-node );

    This method behaves like *findnodes *, except that it only returns a Bool value (True if the expression matches a node, False otherwise) and may be faster than *findnodes *, because the XPath evaluation may stop early on the first match. 

    For XPath expressions that do not return node-sets, the method returns True if the returned value is a non-zero number or a non-empty string.

  * contextNode

        $xpc.contextNode = $node;
        $node = $xpc.contextNode

    Set or get the current context node.

  * contextPosition

        $xpc.contextPosition = $position;
        $position = $xpc.contextPosition;

    Set or get the current context position. By default, this value is -1 (and evaluating XPath function `position() ` in the initial context raises an XPath error), but can be set to any value up to context size. This usually only serves to cheat the XPath engine to return given position when `position() ` XPath function is called. Setting this value to -1 restores the default behavior.

  * contextSize

        $xpc.setContextSize = $size;

    Set or get the current context size. By default, this value is -1 (and evaluating XPath function `last() ` in the initial context raises an XPath error), but can be set to any non-negative value. This usually only serves to cheat the XPath engine to return the given value when `last() ` XPath function is called. If context size is set to 0, position is automatically also set to 0. If context size is positive, position is automatically set to 1. Setting context size to -1 restores the default behavior.

  * query-handler, querySelector, querySelectorAll

    These methods provide pluggable support for CSS Selectors, as described in https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE.

    The query handler is a third-party class or object that implements a method `$.query-to-xpath(Str $selector --> Str) {...}`, that typically maps CSS selectors to XPath querys.

    The handler may be configured globally:

        # set up a global query selector. use the CSS::Selector::To::XPath module
        use CSS::Selector::To::XPath;
        use LibXML::Config;
        LibXML::Config.query-handler = CSS::Selector::To::XPath.new;

        # run queries
        my LibXML::Document $doc .= new: string => q:to<\_(ツ)_/>;
          <table id="score">
            <thead>
              <tr>  <th>Test</th>     <th>Result</th> </tr>
            <thead>
            <tbody>
              <tr>  <td>A</td>        <td>87%</td>     </tr>
              <tr>  <td>B</td>        <td>78%</td>     </tr>
              <tr>  <td>C</td>        <td>81%</td>     </tr>
            </tbody>
            <tfoot>
              <tr>  <th>Average</th>  <td>82%</td>     </tr>
            </tfoot>
          </table>
        \_(ツ)_/

        my $result-query = "#score>tbody>tr>td:nth-of-type(2)"
        my @abc-results = $document.querySelectorAll($result-query);
        my $a-result = $document.querySelector($result-query);

  * set-options, suppress-warnings, suppress-errors

        my LibXML::XPath::Context $ctx .= new: :suppress-warnings;
        $ctx.suppress-errors = True;

    XPath Contexts have some Boolean error handling options:

      * `suppress-warnings` - Don't report warnings

      * `suppress-errors` - Don't report or handle errors

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

