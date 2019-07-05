### multi method setContextNode

```perl6
multi method setContextNode(
    LibXML::Node:D $!context-node
) returns Mu
```

defining the context node

### multi method setContextNode

```perl6
multi method setContextNode(
    LibXML::Node:U $!context-node
) returns Mu
```

undefining the context node

NAME
====

LibXML::XPathContext - XPath Evaluation

SYNOPSIS
========

    use LibXML::XPathContext;
    use LibXML::Node;
    my LibXML::XPath::Context $xpc .= new();
    $xpc .= new(:$node);
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
    my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $ref-node );
    my $object = $xpc.find($xpath );
    $object = $xpc.find($xpath, $ref-node );
    my $value = $xpc.findvalue($xpath );
    $value = $xpc.findvalue($xpath, $ref-node );
    my Bool $found = $xpc.exists( $xpath, $ref-node );
    $xpc.setContextNode($node);
    $node = $xpc.getContextNode;
    my Int $position = $xpc.getContextPosition;
    $xpc.setContextPosition($position);
    my Int $size = $xpc.getContextSize;
    $xpc.setContextSize($size);

DESCRIPTION
===========

The LibXML::XPath::Context class provides an almost complete interface to libxml2's XPath implementation. With LibXML::XPath::Context, it is possible to evaluate XPath expressions in the context of arbitrary node, context size, and context position, with a user-defined namespace-prefix mapping, custom XPath functions written in Perl, and even a custom XPath variable resolver. 

*** TOD: Port this POD to Perl 6 ***

EXAMPLES
========

Namespaces
----------

This example demonstrates `registerNs() ` method. It finds all paragraph nodes in an XHTML document.

    my $xc = LibXML::XPath::Context.new($xhtml-doc);
    $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    my @nodes = $xc.findnodes('//xhtml:p');

Custom XPath functions
----------------------

This example demonstrates `registerFunction() ` method by defining a function filtering nodes based on a Perl regular expression:

    sub grep-nodes {
      my ($nodelist,$regexp) =  @_;
      my $result = LibXML::NodeList.new;
      for my $node ($nodelist.get-nodelist()) {
        $result.push($node) if $node.textContent =~ $regexp;
      }
      return $result;
    };

    my $xc = LibXML::XPath::Context.new($node);
    $xc.registerFunction('grep-nodes', \&grep-nodes);
    my @nodes = $xc.findnodes('//section[grep-nodes(para,"\bsearch(ing|es)?\b")]');

Variables
---------

This example demonstrates `registerVarLookup() ` method. We use XPath variables to recycle results of previous evaluations:

    sub var-lookup {
      my ($varname,$ns,$data)=@_;
      return $data.{$varname};
    }

    my $areas = LibXML.new.parse: :file('areas.xml');
    my $empl = LibXML.new.parse: :file('employees.xml');

    my $xc = LibXML::XPath::Context.new($empl);

    my %variables = (
      A => $xc.find('/employees/employee[@salary>10000]'),
      B => $areas.find('/areas/area[district='Brooklyn']/street'),
    );

    # get names of employees from $A working in an area listed in $B
    $xc.registerVarLookupFunc(\&var-lookup, \%variables);
    my @nodes = $xc.findnodes('$A[work_area/street = $B]/name');

METHODS
=======

  * new

        my $xpc = LibXML::XPath::Context.new();

    Creates a new LibXML::XPath::Context object without a context node.

        my $xpc = LibXML::XPath::Context.new($node);

    Creates a new LibXML::XPath::Context object with the context node set to `$node `.

  * registerNs

        $xpc.registerNs($prefix, $namespace-uri)

    Registers namespace `$prefix ` to `$namespace-uri `.

  * unregisterNs

        $xpc.unregisterNs($prefix)

    Unregisters namespace `$prefix `.

  * lookupNs

        $uri = $xpc.lookupNs($prefix)

    Returns namespace URI registered with `$prefix `. If `$prefix ` is not registered to any namespace URI returns `undef `.

  * registerVarLookupFunc

        $xpc.registerVarLookupFunc($callback, $data)

    Registers variable lookup function `$prefix `. The registered function is executed by the XPath engine each time an XPath variable is evaluated. It takes three arguments: `$data `, variable name, and variable ns-URI and must return one value: a number or string or any `LibXML:: ` object that can be a result of findnodes: Boolean, Literal, Number, Node (e.g. Document, Element, etc.), or NodeList. For convenience, simple (non-blessed) array references containing only [LibXML::Node ](LibXML::Node ) objects can be used instead of an [LibXML::NodeList ](LibXML::NodeList ).

  * getVarLookupData

        $data = $xpc.getVarLookupData();

    Returns the data that have been associated with a variable lookup function during a previous call to `registerVarLookupFunc `.

  * getVarLookupFunc

        $callback = $xpc.getVarLookupFunc();

    Returns the variable lookup function previously registered with `registerVarLookupFunc `.

  * unregisterVarLookupFunc

        $xpc.unregisterVarLookupFunc($name);

    Unregisters variable lookup function and the associated lookup data.

  * registerFunctionNS

        $xpc.registerFunctionNS($name, $uri, $callback)

    Registers an extension function `$name ` in `$uri ` namespace. `$callback ` must be a CODE reference. The arguments of the callback function are either simple scalars or `LibXML::* ` objects depending on the XPath argument types. The function is responsible for checking the argument number and types. Result of the callback code must be a single value of the following types: a simple scalar (number, string) or an arbitrary `LibXML::* ` object that can be a result of findnodes: Boolean, Literal, Number, Node (e.g. Document, Element, etc.), or NodeList. For convenience, simple (non-blessed) array references containing only [LibXML::Node ](LibXML::Node ) objects can be used instead of a [LibXML::NodeList ](LibXML::NodeList ).

  * unregisterFunctionNS

        $xpc.unregisterFunctionNS($name, $uri)

    Unregisters extension function `$name ` in `$uri ` namespace. Has the same effect as passing `undef ` as `$callback ` to registerFunctionNS.

  * registerFunction

        $xpc.registerFunction($name, $callback)

    Same as `registerFunctionNS ` but without a namespace.

  * unregisterFunction

        $xpc.unregisterFunction($name)

    Same as `unregisterFunctionNS ` but without a namespace.

  * findnodes

        @nodes = $xpc.findnodes($xpath)

        @nodes = $xpc.findnodes($xpath, $context-node )

        $nodelist = $xpc.findnodes($xpath, $context-node )

    Performs the xpath statement on the current node and returns the result as an array. In scalar context, returns an [LibXML::NodeList ](LibXML::NodeList ) object. Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

  * find

        $object = $xpc.find($xpath )

        $object = $xpc.find($xpath, $context-node )

    Performs the xpath expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath `1 * 3 + 52 ` results in an [LibXML::Number ](LibXML::Number ) object being returned. Other expressions might return a [LibXML::Boolean ](LibXML::Boolean ) object, or a [LibXML::Literal ](LibXML::Literal ) object (a string). Each of those objects uses Perl's overload feature to ``do the right thing'' in different contexts. Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

  * findvalue

        $value = $xpc.findvalue($xpath )

        $value = $xpc.findvalue($xpath, $context-node )

    Is exactly equivalent to:

        $xpc.find( $xpath, $context-node ).to-literal;

    That is, it returns the literal value of the results. This enables you to ensure that you get a string back from your search, allowing certain shortcuts. This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>. Optionally, a node may be passed in the second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a [LibXML::XPathExpression ](LibXML::XPathExpression ) object. 

  * exists

        $bool = $xpc.exists( $xpath-expression, $context-node );

    This method behaves like *findnodes *, except that it only returns a boolean value (1 if the expression matches a node, 0 otherwise) and may be faster than *findnodes *, because the XPath evaluation may stop early on the first match (this is true for libxml2 >= 2.6.27). 

    For XPath expressions that do not return node-set, the method returns true if the returned value is a non-zero number or a non-empty string.

  * setContextNode

        $xpc.setContextNode($node)

    Set the current context node.

  * getContextNode

        my $node = $xpc.getContextNode;

    Get the current context node.

  * setContextPosition

        $xpc.setContextPosition($position)

    Set the current context position. By default, this value is -1 (and evaluating XPath function `position() ` in the initial context raises an XPath error), but can be set to any value up to context size. This usually only serves to cheat the XPath engine to return given position when `position() ` XPath function is called. Setting this value to -1 restores the default behavior.

  * getContextPosition

        my $position = $xpc.getContextPosition;

    Get the current context position.

  * setContextSize

        $xpc.setContextSize($size)

    Set the current context size. By default, this value is -1 (and evaluating XPath function `last() ` in the initial context raises an XPath error), but can be set to any non-negative value. This usually only serves to cheat the XPath engine to return the given value when `last() ` XPath function is called. If context size is set to 0, position is automatically also set to 0. If context size is positive, position is automatically set to 1. Setting context size to -1 restores the default behavior.

  * getContextSize

        my $size = $xpc.getContextSize;

    Get the current context size.

  * setContextNode

        $xpc.setContextNode($node)

    Set the current context node.

BUGS AND CAVEATS
================

LibXML::XPath::Context objects *are * reentrant, meaning that you can call methods of an LibXML::XPath::Context even from XPath extension functions registered with the same object or from a variable lookup function. On the other hand, you should rather avoid registering new extension functions, namespaces and a variable lookup function from within extension functions and a variable lookup function, unless you want to experience untested behavior. 

AUTHORS
=======

Ilya Martynov and Petr Pajas, based on LibXML and XML::LibXSLT code by Matt Sergeant and Christian Glahn.

HISTORICAL REMARK
=================

Prior to LibXML 1.61 this module was distributed separately for maintenance reasons. 

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

