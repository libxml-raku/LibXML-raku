class LibXML::Pattern
---------------------

interface to libxml2 XPath patterns

Synopsis
--------

```raku
use LibXML;
my LibXML::Pattern $pattern = complie('/x:html/x:body//x:div', :ns{ 'x' => 'http://www.w3.org/1999/xhtml' });
# test a match on an LibXML::Node $node

if $pattern.matchesNode($node) { ... }
if $node ~~ $pattern { ... }

# or on an LibXML::Reader

if $reader.matchesPattern($pattern) { ... }

# or skip reading all nodes that do not match

print $reader.nodePath while $reader.nextPatternMatch($pattern);

my LibXML::Pattern $pattern .= new( pattern, :ns{prefix => namespace_URI} );
my Bool $matched = $pattern.matchesNode($node);
```

Description
-----------

This is a Raku interface to libxml2's pattern matching support *http://xmlsoft.org/html/libxml-pattern.html *. This feature requires recent versions of libxml2.

Patterns are a small subset of XPath language, which is limited to (disjunctions of) location paths involving the child and descendant axes in abbreviated form as described by the extended BNF given below: 

```bnf
Selector ::=     Path ( '|' Path )*
Path     ::=     ('.//' | '//' | '/' )? Step ( '/' Step )*
Step     ::=     '.' | NameTest
NameTest ::=     QName | '*' | NCName ':' '*'
```

For readability, whitespace may be used in selector XPath expressions even though not explicitly allowed by the grammar: whitespace may be freely added within patterns before or after any token, where

```bnf
token     ::=     '.' | '/' | '//' | '|' | NameTest
```

Note that no predicates or attribute tests are allowed.

Patterns are particularly useful for stream parsing provided via the [LibXML::Reader ](https://libxml-raku.github.io/LibXML-raku/Reader) interface.

Methods
-------

### method new

```raku
method new( Str :$pattern!, Str :%ns, *%opts) returns LibXML::Pattern
```

The constructors of a pattern takes a pattern expression (as described by the BNF grammar above) and an optional Hash mapping prefixes to namespace URIs. The methods return a compiled pattern object. 

Note that if the document has a default namespace, it must still be given an prefix in order to be matched (as demanded by the XPath 1.0 specification). For example, to match an element `<a xmlns="http://foo.bar"/>`, one should use a pattern like this: 

```raku
my LibXML::Pattern $pattern .= compile( 'foo:a', :ns(foo => 'http://foo.bar') );
```

### method compile

```raku
method new( Str $pattern!, Str :%ns, *%opts) returns LibXML::Pattern
```

`LibXML::Pattern.compile($pattern)` is equivalent to `LibXML::Pattern.new(:$pattern)`.

### multi method matchesNode

```perl6
multi method matchesNode(
    LibXML::Node $node
) returns Bool
```

True if the node is matched by the compiled pattern

### multi method ACCEPTS

```perl6
multi method ACCEPTS(
    LibXML::Node:D $node
) returns Bool
```

True if the Node matches the pattern

Example:

```raku
my Bool $valid = $elem ~~ $pattern;
```

See Also
--------

[LibXML::Reader](https://libxml-raku.github.io/LibXML-raku/Reader) for other methods involving compiled patterns.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

