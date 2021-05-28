[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [XPath](https://libxml-raku.github.io/LibXML-raku/XPath)
 :: [Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context)

class LibXML::XPath::Context
----------------------------

XPath Evaluation Context

Synopsis
--------

    use LibXML::XPathContext;
    use LibXML::Node;
    my LibXML::XPath::Context $xpc .= new();

    $xpc .= new(:$node, :suppress-warnings, :suppress-errors);
    $xpc.registerNs($prefix, $namespace-uri);
    # -OR-
    $xpc .= new(:$node, :ns{ $prefix => $namespace-uri, });

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

Description
-----------

The LibXML::XPath::Context class provides an almost complete interface to libxml2's XPath implementation. With LibXML::XPath::Context, it is possible to evaluate XPath expressions in the context of arbitrary node, context size, and context position, with a user-defined namespace-prefix mapping, custom XPath functions written in Raku, and even a custom XPath variable resolver.

Examples
--------

### 1. Namespaces

This example demonstrates `registerNs()` method. It finds all paragraph nodes in an XHTML document.

    my LibXML::XPath::Context $xc .= new: doc($xhtml-doc);
    $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
    my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');

Alternatively, namespaces can be defined on the constructor:

    my LibXML::XPath::Context $xc .= new: doc($xhtml-doc), :ns{ xhtml => 'http://www.w3.org/1999/xhtml' };
    my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');

### 2. Custom XPath functions

This example demonstrates `registerFunction()` method by defining a function filtering nodes based on a Raku regular expression:

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

### 3. Variables

This example demonstrates `registerVarLookup()` method. We use XPath variables to recycle results of previous evaluations:

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

Methods
-------

### method new

```raku
multi method new(LibXML::Document :$doc!, :%ns) returns LibXML::XPath::Context;
multi method new(LibXML::Node :$node, :%ns) returns LibXML::XPath::Context;
```

Creates a new LibXML::XPath::Context object with an optional context document or node, and `:%ns`, mapping of prefixes to namespace URI's.

### method registerNs

```raku
multi method registerNs(NCName:D :$prefix!, Str :$uri) returns 0
multi method registerNs(NCName:D $prefix!, Str $uri?) returns 0
multi method registerNs(LibXML::Namespace:D $ns) returns 0
```

Registers a namespace with a given prefix and uri.

A uri of Str:U will unregister any namespace with the given prefix.

### method unregisterNs

```raku
multi method unregisterNs(NCName:D :$prefix!) returns 0
multi method unregisterNs(NCName:D $prefix!) returns 0
multi method unregisterNs(LibXML::Namespace:D $ns) returns 0
```

Unregisters a namespace with the given prefix

### method lookupNs

```raku
method lookupNs(
    Str:D $prefix where { ... }
) returns Str
```

Returns namespace URI registered with $prefix.

If `$prefix` is not registered to any namespace URI returns `Str:U`.

### method registerVarLookupFunc

```raku
method registerVarLookupFunc(
    &callback,
    |args
) returns Mu
```

Registers a variable lookup function.

The registered function is executed by the XPath engine each time an XPath variable is evaluated. The callback function has two required arguments: `$name`, variable name, and `$uri`.

The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g. Document, Element, etc.), [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) or [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List).

For convenience, types: List, Seq and Slip can also be returned, these should contain only [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) objects.

Any additional arguments are captured and passed to the callback function. For example:

```raku
$xpc.registerVarLookupFunc(&my-callback, 'Xxx', :%vars);
```

matches the signature:

```raku
sub my-callback(Str $name, Str $uri, 'Xxx', :%vars!) {
  ...
}
```

### method unregisterVarLookupFunc

```raku
method unregisterVarLookupFunc() returns Mu
```

Removes the variable lookup function. Disables variable lookup

### method getVarLookupFunc

```raku
method getVarLookupFunc() returns Routine
```

Gets the current variable lookup function

### method registerFunctionNS

```raku
method registerFunctionNS(
    Str:D $name where { ... },
    Str $uri,
    &func,
    |args
) returns Mu
```

Registers an extension function $name in $uri namespace

The arguments of the callback function are either simple scalars or `LibXML::*` objects depending on the XPath argument types.

The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g. Document, Element, etc.), [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) or [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List).

For convenience, types: List, Seq and Slip can also be returned, these shoulf contain only [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) objects.

### method unregisterFunctionNS

```raku
method unregisterFunctionNS(
    Str:D $name where { ... },
    Str $uri
) returns Mu
```

Unregisters extension function $name in $uri namespace.

### method register-function

```raku
method register-function(
    Str $url,
    Str:D $name where { ... },
    &func,
    |c
) returns Mu
```

Like registerFunctionNS; same argument order as LibXSLT.register-function()

### method registerFunction

```raku
method registerFunction(
    Str:D $name where { ... },
    &func,
    |c
) returns Mu
```

Same as registerFunctionNS but without a namespace.

### method unregisterFunction

```raku
method unregisterFunction(
    Str:D $name where { ... }
) returns Mu
```

Same as unregisterFunctionNS but without a namespace.

### method findnodes

```raku
multi method findnodes(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) returns LibXML::Node::Set;
multi method findnodes(Str:D $expr, LibXML::Node $ref?, Bool :$deref) returns LibXML::Node::Set;
# Examples
my LibXML::Node @nodes = $xpc.findnodes($xpath);
@nodes = $xpc.findnodes($xpath, $context-node );
my LibXML::Node::Set $nodes = $xpc.findnodes($xpath);
for  $xpc.findnodes($xpath) { ... }
```

Performs the xpath statement on the current node and returns the result as an [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) object.

Optionally, a node may be passed as a second argument to set the context node for the query.

The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

### method first

```raku
  multi method first(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns LibXML::Item;
  multi method first(Str:D $expr, LibXML::Node $ref?) returns LibXML::Item;
  my LibXML::Node $body = $doc.first('body');
```

The `first` method is similar to `findnodes`, except it returns a single node representing the first matching row. If no nodes were found, `LibXML::Node:U` is returned.

### method last

```raku
  my LibXML::Node $last-row = $body.last('descendant::tr');
```

The `last` method is similar to `first`, except it returns the last rather than the first matching row.

### method AT-KEY

```raku
method AT-KEY(
    $_,
    Bool :$deref = Bool::True
) returns LibXML::Node::Set
```

Alias for findnodes($_, :deref)

Example

```raku
my LibXML::XPath::Context $xpc .= new: :node($table-elem);
for $xpc<tr> -> LibXML::Element $row-elem {...}
```

### method find

```raku
multi method find(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) returns Any;
multi method find(Str:D $expr, LibXML::Node $ref?, Bool :$deref) returns Any;
my Any $object = $xpc.find($xpath );
$object = $xpc.find($xpath, $context-node );
```

Finds nodes or values.

Performs the xpath expression using the current node as the context of the expression, and returns the result depending on what type of result the XPath expression had. For example, the XPath `1 * 3 + 52` results in a Numeric object being returned. Other expressions might return a Bool object, or a string. Optionally, a node may be passed as a second argument to set the context node for the query.

The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

### method findvalue

```raku
multi method findvalue(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns Any;
multi method findvalue(Str:D $expr, LibXML::Node $ref?) returns Any;
```

Returns only a simple value as string, numeric or boolean.

An expression that would return an [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) is coerced by calling `string-value()` on each of its members and joing the result.

This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>.

Optionally, a node may be passed in the second argument to set the context node for the query.

The xpath expression can be passed either as a string, or as a [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) object.

### method exists

```raku
multi method exists(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns Bool;
multi method exists(Str:D $expr, LibXML::Node $ref?) returns Bool;
```

This method behaves like *find*, except that it only returns a Bool value (True if the expression matches a node, False otherwise) and may be faster than *find*, because the XPath evaluation may stop early on the first match.

For XPath expressions that do not return node-sets, the method returns True if the returned value is a non-zero number or a non-empty string.

### method contextNode

```raku
method contextNode() returns LibXML::Node
```

Set or get the context node

### method contextPosition

```raku
method contextPosition() returns Int
```

Set or get the current context position.

By default, this value is -1 (and evaluating XPath function `position()` in the initial context raises an XPath error), but can be set to any value up to context size. This usually only serves to cheat the XPath engine to return given position when `position()` XPath function is called.

Setting this value to -1 restores the default behavior.

### method contextSize

```raku
method contextSize() returns Int
```

Set or get the current context size.

By default, this value is -1 (and evaluating XPath function `last()` in the initial context raises an XPath error), but can be set to any non-negative value. This usually only serves to cheat the XPath engine to return the given value when `last()` XPath function is called.

  * If context size is set to 0, position is automatically also set to 0.

  * If context size is positive, position is automatically set to 1. Setting context size to -1 restores the default behavior.

### methods query-handler, querySelector, querySelectorAll

These methods provide pluggable support for CSS Selectors, as described in https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE.

The query handler is a third-party class or object that implements a method `$.query-to-xpath(Str $selector --> Str) {...}`, that typically maps CSS selectors to XPath querys.

The handler may be configured globally:

```raku
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
```

### methods set-options, suppress-warnings, suppress-errors

```raku
 my LibXML::XPath::Context $ctx .= new: :suppress-warnings;
 $ctx.suppress-errors = True;
```

XPath Contexts have some Boolean error handling options:

  * `suppress-warnings` - Don't report warnings

  * `suppress-errors` - Don't report or handle errors

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

